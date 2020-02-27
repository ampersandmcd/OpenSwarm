#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Thu Jun  1 09:02:36 2017

@author: Paris
"""

from __future__ import division, print_function
import pandas as pd
import autograd.numpy as np
import matplotlib.pyplot as plt
import matplotlib
import matlab
from matplotlib import cm
import numpy
from pyDOE import lhs
from gaussian_process import Multifidelity_GP
from mpl_toolkits.mplot3d.axes3d import Axes3D
from scipy.optimize import differential_evolution
# import seaborn as sns
# from concorde.tsp import TSPSolver
from scipy.spatial import distance_matrix


# np.random.seed(1234)

def train_MFGP(X_Lmem, y_Lmem, X_Hmem, y_Hmem):
    # Train interface with matlab

    # Convert to numpy from memoryview objects passed by matlab
    X_L = np.asarray(X_Lmem)
    y_L = np.asarray(y_Lmem)
    X_H = np.asarray(X_Hmem)
    y_H = np.asarray(y_Hmem)

    # Reshape to n by 1 vectors
    y_L = y_L[:, np.newaxis]
    y_H = y_H[:, np.newaxis]

    # Construct and train model
    model = Multifidelity_GP(X_L, y_L, X_H, y_H)
    model.train()
    return model


def predict_MFGP(model, X_star):
    # Prediction interface with matlab

    # Predict given test points
    pred_u_star, var_u_star = model.predict(X_star)

    # Return mu and var
    return matlab.double(pred_u_star.tolist())

# def tsp_solve(X):
#     if X.shape[0] < 4:
#         return X
#     else:
#         lat = pd.Series(X[:, 0])
#         lon = pd.Series(X[:, 1])
#         solver = TSPSolver.from_data(lat, lon, norm="EUC_2D")
#         sort_data = solver.solve()
#         assert sort_data.success
#         tour = X[sort_data.tour, :]
#         # plot_tsp(X)
#         return tour


def plot_tsp(X):

    plt.plot(X[:, 0], X[:, 1], 'ro-')
    plt.show()


def test_func(arg):
    array = np.asarray(arg)
    print(array)


if __name__ == "__main__":
    # number of hi fidelity samples
    N_H = 50
    # number of low fidelity samples
    N_L = 50
    # dimension of input (2)
    D = 2

    lb = np.array([-3, -3])
    ub = np.array([3, 3])
    # rectangular field over which GP is defined
    Bound = (lb, ub)
    model = train_MFGP(N_H, N_L, Bound)

    hyp = model.hyp
    hyp = np.exp(hyp)
    rho = hyp[-3]
    sigma_n_L = hyp[-2] * rho ** 2
    sigma_n_H = hyp[-1]
    theta_L = hyp[model.idx_theta_L]
    theta_H = hyp[model.idx_theta_H]
    len_L = theta_L[2]
    len_H = theta_H[2]
    var_L = theta_L[1] * rho ** 2
    var_H = theta_H[1]
    mean_L = theta_L[0]
    mean_H = rho * mean_L + theta_H[0]

    # sw_pt_L = ((len_H / len_L) ** 2 * sigma_n_L / sigma_n_H + 1) * var_H

    sw_pt_L = 1.2 * var_H

    model.X_L = np.empty([0, 2])
    model.y_L = np.empty([0, 1])
    model.X_H = np.empty([0, 2])
    model.y_H = np.empty([0, 1])

    var = var_L + var_H

    dlt = 0.05
    thrd = 39
    j = 0

    ter_max = 1.1 * var_H

    max_var = float("inf")
    max_var_list = np.zeros(5)
    s = 0

    while max_var >= ter_max:
        X_L_new = np.empty([0, 2])
        X_H_new = np.empty([0, 2])
        y_L_new = np.empty([0, 1])
        y_H_new = np.empty([0, 1])
        model.updt_info(X_L_new, y_L_new, X_H_new, y_H_new)
        c = np.sqrt(2 * np.log(2 ** j / dlt))
        my_plot_search.plot_mdl(model, Bound, 50, thrd, c)
        while max_var >= max(0.75 ** 2 * var, ter_max):
            x, max_var = model.get_max_var(Bound, thrd, c, X_L_new, X_H_new)
            # x, max_var = model.get_max_var(Bound, 39, 3, X_L_new, X_H_new)
            if max_var <= sw_pt_L:
                X_H_new = np.vstack((X_H_new, x))
            else:
                X_L_new = np.vstack((X_L_new, x))
            print("Round: %d, LF point no.:%d, HF point.no.: %d" %
                  (j + 1, X_L_new.shape[0], X_H_new.shape[0]))
            print("Maximum variance: %f" % (max_var))
            max_var_list[:-1] = max_var_list[1:]
            max_var_list[-1] = max_var
            my_plot_search.plot_var(max_var_list, s)
            s = s + 1
        var = max_var
        my_plot_search.plot_line(X_L_new, X_H_new)

        # fig = plot_mdl(model, Bound, 50, thrd, c, X_L_new, X_H_new)
        plt.pause(1.)
        # X_L_new = tsp_solve(X_L_new)
        y_L_new = f_L(X_L_new)
        # X_H_new = tsp_solve(X_H_new)
        y_H_new = f_H(X_H_new)

        # fig.axes[3].lines[0] = []
        # fig.canvas.draw()
        # plt.pause(0.5)
        # fig.axes[3].plot(X_L_new[:, 0], X_L_new[:, 1], 2, 'ro-')
        # fig.canvas.draw()
        # plt.pause(0.5)

        model.updt_info(X_L_new, y_L_new, X_H_new, y_H_new)
        print("Round: %d is finished" % (j + 1))
        j = j + 1

    X_L_new = np.empty([0, 2])
    X_H_new = np.empty([0, 2])
    # plot_mdl(model, Bound, 50, thrd, c, X_L_new, X_H_new)
