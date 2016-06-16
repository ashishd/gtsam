/**
 * @file     LPSolver.cpp
 * @brief    
 * @author   Duy Nguyen Ta
 * @author   Ivan Dario Jimenez
 * @date     1/26/16
 */

#include <gtsam_unstable/linear/LPSolver.h>
#include <gtsam_unstable/linear/InfeasibleInitialValues.h>
#include <gtsam/linear/GaussianFactorGraph.h>
#include <gtsam_unstable/linear/LPInitSolver.h>

namespace gtsam {
//******************************************************************************
LPSolver::LPSolver(const LP &lp) :
    ActiveSetSolver(std::numeric_limits<double>::infinity()), lp_(lp) {
  // Variable index
  equalityVariableIndex_ = VariableIndex(lp_.equalities);
  inequalityVariableIndex_ = VariableIndex(lp_.inequalities);
  constrainedKeys_ = lp_.equalities.keys();
  constrainedKeys_.merge(lp_.inequalities.keys());
}

//******************************************************************************
LPState LPSolver::iterate(const LPState &state) const {
  // Solve with the current working set
  // LP: project the objective neg. gradient to the constraint's null space
  // to find the direction to move
  VectorValues newValues = solveWithCurrentWorkingSet(state.values,
      state.workingSet);
  // If we CAN'T move further
  // LP: projection on the constraints' nullspace is zero: we are at a vertex
  if (newValues.equals(state.values, 1e-7)) {
    // Find and remove the bad inequality constraint by computing its lambda
    // Compute lambda from the dual graph
    // LP: project the objective's gradient onto each constraint gradient to
    // obtain the dual scaling factors
    //  is it true??
    GaussianFactorGraph::shared_ptr dualGraph = buildDualGraph(state.workingSet,
        newValues);
    VectorValues duals = dualGraph->optimize();
    // LP: see which inequality constraint has wrong pulling direction, i.e., dual < 0
    int leavingFactor = identifyLeavingConstraint(state.workingSet, duals);
    // If all inequality constraints are satisfied: We have the solution!!
    if (leavingFactor < 0) {
      // TODO If we still have infeasible equality constraints: the problem is
      // over-constrained. No solution!
      // ...
      return LPState(newValues, duals, state.workingSet, true,
          state.iterations + 1);
    } else {
      // Inactivate the leaving constraint
      // LP: remove the bad ineq constraint out of the working set
      InequalityFactorGraph newWorkingSet = state.workingSet;
      newWorkingSet.at(leavingFactor)->inactivate();
      return LPState(newValues, duals, newWorkingSet, false,
          state.iterations + 1);
    }
  } else {
    // If we CAN make some progress, i.e. p_k != 0
    // Adapt stepsize if some inactive constraints complain about this move
    // LP: projection on nullspace is NOT zero:
    //    find and put a blocking inactive constraint to the working set,
    //    otherwise the problem is unbounded!!!
    double alpha;
    int factorIx;
    VectorValues p = newValues - state.values;
//    GTSAM_PRINT(p);
    boost::tie(alpha, factorIx) = // using 16.41
        computeStepSize(state.workingSet, state.values, p);
    // also add to the working set the one that complains the most
    InequalityFactorGraph newWorkingSet = state.workingSet;
    if (factorIx >= 0)
      newWorkingSet.at(factorIx)->activate();
    // step!
    newValues = state.values + alpha * p;
    return LPState(newValues, state.duals, newWorkingSet, false,
        state.iterations + 1);
  }
}

//******************************************************************************
GaussianFactorGraph::shared_ptr LPSolver::createLeastSquareFactors(
    const LinearCost &cost, const VectorValues &xk) const {
  GaussianFactorGraph::shared_ptr graph(new GaussianFactorGraph());
  for (LinearCost::const_iterator it = cost.begin(); it != cost.end(); ++it) {
    size_t dim = cost.getDim(it);
    Vector b = xk.at(*it) - cost.getA(it).transpose(); // b = xk-g
    graph->push_back(JacobianFactor(*it, Matrix::Identity(dim, dim), b));
  }

  KeySet allKeys = lp_.inequalities.keys();
  allKeys.merge(lp_.equalities.keys());
  allKeys.merge(KeySet(lp_.cost.keys()));
  // Add corresponding factors for all variables that are not explicitly in the
  // cost function. Gradients of the cost function wrt to these variables are 
  // zero (g=0), so b=xk
  if (cost.keys().size() != allKeys.size()) {
    KeySet difference;
    std::set_difference(allKeys.begin(), allKeys.end(), lp_.cost.begin(),
        lp_.cost.end(), std::inserter(difference, difference.end()));
    for (Key k : difference) {
      size_t dim = lp_.constrainedKeyDimMap().at(k);
      graph->push_back(JacobianFactor(k, Matrix::Identity(dim, dim), xk.at(k)));
    }
  }
  return graph;
}

//******************************************************************************
VectorValues LPSolver::solveWithCurrentWorkingSet(const VectorValues &xk,
    const InequalityFactorGraph &workingSet) const {
  GaussianFactorGraph workingGraph;
  // || X - Xk + g ||^2
  workingGraph.push_back(*createLeastSquareFactors(lp_.cost, xk));
  workingGraph.push_back(lp_.equalities);
  for (const LinearInequality::shared_ptr &factor : workingSet) {
    if (factor->active())
      workingGraph.push_back(factor);
  }
  return workingGraph.optimize();
}

//******************************************************************************
boost::shared_ptr<JacobianFactor> LPSolver::createDualFactor(
    Key key, const InequalityFactorGraph &workingSet,
    const VectorValues &delta) const {
  // Transpose the A matrix of constrained factors to have the jacobian of the
  // dual key
  TermsContainer Aterms = collectDualJacobians<LinearEquality>(
      key, lp_.equalities, equalityVariableIndex_);
  TermsContainer AtermsInequalities = collectDualJacobians<LinearInequality>(
      key, workingSet, inequalityVariableIndex_);
  Aterms.insert(Aterms.end(), AtermsInequalities.begin(),
                AtermsInequalities.end());

  // Collect the gradients of unconstrained cost factors to the b vector
  if (Aterms.size() > 0) {
    Vector b = lp_.costGradient(key, delta);
    // to compute the least-square approximation of dual variables
    return boost::make_shared<JacobianFactor>(Aterms, b);
  } else {
    return boost::make_shared<JacobianFactor>();
  }
}

//******************************************************************************
std::pair<VectorValues, VectorValues> LPSolver::optimize(
    const VectorValues &initialValues, const VectorValues &duals) const {
  {
    // Initialize workingSet from the feasible initialValues
    InequalityFactorGraph workingSet = identifyActiveConstraints(
        lp_.inequalities, initialValues, duals);
    LPState state(initialValues, duals, workingSet, false, 0);

    /// main loop of the solver
    while (!state.converged) {
      state = iterate(state);
    }
    return make_pair(state.values, state.duals);
  }
}

//******************************************************************************
pair<VectorValues, VectorValues> LPSolver::optimize() const {
  LPInitSolver initSolver(lp_);
  VectorValues initValues = initSolver.solve();
  return optimize(initValues);
}
}

