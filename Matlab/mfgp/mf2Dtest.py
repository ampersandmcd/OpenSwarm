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

class Plot_Search:
    def __init__(self):
        matplotlib.rcParams['toolbar'] = 'None'
        self.fig = plt.figure("Search", figsize=[9,9])
        self.fig.tight_layout()
        self.fig.canvas.manager.window.wm_geometry('+962+1190')
        plt.subplots_adjust(left =0, wspace = 0, hspace = 0.1)
        plt.show(block=False)
        # plt.autoscale()

    def plot_mdl(self, model, bound, nn, thrd, c):
        self.fig.clf()
        # Test data
        nn = complex(0, nn)
        # X_star = np.linspace(lb, ub, nn)
        X_star = numpy.mgrid[bound[0][0]:bound[1][0]:nn, bound[0][1]:bound[1][1]:nn]
        x = numpy.transpose(np.array([np.ravel(X_star[0]), np.ravel(X_star[1])]))
        z_pred, z_var = model.predict(x)
        z_pred = np.ravel(z_pred)
        z_var = np.abs(np.diag(z_var))
        x = np.ravel(X_star[0])
        y = np.ravel(X_star[1])

        # ax.disable_mouse_rotation()
        # ax.set_aspect("equal")
        # ax.plot_surface(x, y, z_pred, color='r')
        self.ax1 = self.fig.add_subplot(222, projection='3d', proj_type='ortho')
        self.ax1.view_init(azim=-90, elev=90)
        surf = self.ax1.plot_trisurf(x, y, z_var, cmap=cm.jet, linewidth=0.1)
        self.fig.colorbar(surf, shrink=0.5, aspect=20)
        self.ax1.set_xlabel("X")
        self.ax1.set_ylabel("Y")
        # self.ax1.set_title("post_var")
        self.ax1.text2D(0.4, 0.1, "post_var", transform=self.ax1.transAxes)

        self.ax2 = self.fig.add_subplot(224, projection='3d', proj_type='ortho')
        self.ax2.view_init(azim=-90, elev=90)
        surf = self.ax2.plot_trisurf(x, y, z_pred, cmap=cm.jet, linewidth=0.1)
        self.fig.colorbar(surf, shrink=0.5, aspect=20)
        self.ax2.set_xlabel("X")
        self.ax2.set_ylabel("Y")
        self.ax2.text2D(0.4, 0.1, "post_mean", transform=self.ax2.transAxes)
        # self.ax2.set_title("post_mean")

        # plt.savefig('teste.pdf')
        # heat_var = sns.heatmap(z_var.reshape(X_star[0].shape), xticklabels=X_star[0][:, 0], yticklabels= X_star[0][:, 0])

        self.ax3 = self.fig.add_subplot(223, projection='3d', proj_type='ortho')
        self.ax3.view_init(azim=-90, elev=90)
        z_cl = np.zeros(z_pred.shape)
        z_cl[z_pred - c * z_var >= thrd] = 1
        z_cl[z_pred + c * z_var <= thrd] = -1
        norm = cm.colors.Normalize(vmax=1, vmin=-1)
        surf = self.ax3.plot_trisurf(x, y, z_cl, norm=norm, cmap=cm.jet, linewidth=0.1)
        self.ax3.set_xlabel("X", verticalalignment = 'bottom',)
        self.ax3.set_ylabel("Y")
        # self.ax3.set_title("classification & traj")
        self.ax3.text2D(0.3, 0.1, "classification & trajectory", transform=self.ax3.transAxes)

        cl_per = 100*numpy.count_nonzero(z_cl)/len(z_cl)


        # plt.savefig('teste.pdf')
        # plt.show()
        # heat_var = sns.heatmap(z_var.reshape(X_star[0].shape), xticklabels=X_star[0][:, 0], yticklabels= X_star[0][:, 0])
        # self.fig.canvas.draw()
        # plt.pause(0.1)
        #
        self.l0 = self.ax3.plot([], [], 2, 'o-', color='darkgreen')
        self.l1 = self.ax3.plot([], [], 2, 'ro-')

        # self.ax4 = self.fig.add_subplot(221, projection='3d', proj_type='ortho')
        # self.ax4.view_init(azim=-90, elev=90)
        # # self.ax4.set_xlabel("sampling rounds")
        # # self.ax4.set_ylabel("max_post_var", x=0.5)
        # self.ax4.text2D(0.1, 0.67, "max_post_var", transform=self.ax4.transAxes,rotation=90)
        # self.ax4.text2D(0.38, 0.1, "sampling rounds", transform=self.ax4.transAxes)
        # self.lvar = self.ax4.plot([], [], 2, 'k-')

        self.ax4 = self.fig.add_subplot(221,position = [0.11,0.58,0.25,0.25])
        self.ax4.grid()
        self.ax4.set_xlabel("sampling rounds")
        self.ax4.set_ylabel("max_post_var")
        # self.ax4.text2D(0.1, 0.67, "max_post_var", transform=self.ax4.transAxes, rotation=90)
        # self.ax4.text2D(0.38, 0.1, "sampling rounds", transform=self.ax4.transAxes)
        self.lvar = self.ax4.plot([], [], 'k-')

        self.fig.canvas.draw()
        # plt.pause(0.05)
        return cl_per

    def plot_line_L(self, X_L_new, score):
        self.l0[0].set_xdata(X_L_new[:, 0])
        self.l0[0].set_ydata(X_L_new[:, 1])
        self.l0[0].set_3d_properties(zs=2)
        self.ax3.title.set_text("score: %f" % score)
        self.fig.canvas.draw()
        # self.ax3.set_title("score: %f" %score)
        # plt.pause(0.05)


    def plot_line_H(self, X_H_new, score):
        self.l1[0].set_xdata(X_H_new[:, 0])
        self.l1[0].set_ydata(X_H_new[:, 1])
        self.l1[0].set_3d_properties(zs=2)
        self.ax3.title.set_text("score: %f" % score)
        # self.ax3.set_title()
        self.fig.canvas.draw()
        # plt.pause(0.05)

    def plot_line(self, X_L_new, X_H_new):
        self.l0[0].set_xdata(X_L_new[:, 0])
        self.l0[0].set_ydata(X_L_new[:, 1])
        self.l0[0].set_3d_properties(zs=2)
        self.l1[0].set_xdata(X_H_new[:, 0])
        self.l1[0].set_ydata(X_H_new[:, 1])
        self.l1[0].set_3d_properties(zs=2)
        self.fig.canvas.draw()
        # plt.pause(0.05)

    def plot_var(self, max_var_list, s):
        xpt = np.array(range(max_var_list.shape[0]))
        xpt = xpt - xpt[-1]+s
        self.lvar[0].set_xdata(xpt)
        self.lvar[0].set_ydata(max_var_list)
        # self.lvar[0].set_3d_properties(zs=0)
        self.ax4.set_xlim([xpt[0], xpt[-1]])
        self.ax4.set_ylim([np.amin(max_var_list), np.amax(max_var_list)])
        self.ax4.title.set_text("new max_post_var: %f" % max_var_list[-1])
        self.fig.canvas.draw()
        # plt.pause(0.5)


my_plot_search = Plot_Search()


def f_H(x):
    noise_H = 0.2
    arg2 = 0.5 * (np.cos(2. * np.pi * x[:, 0]) + np.cos(2. * np.pi * x[:, 1]))
    add = np.exp(arg2)
    add = (add[numpy.newaxis]).T
    return f_L(x) + add + noise_H * np.random.randn(add.size, 1)


def f_L(x):
    noise_L = 0.4
    arg1 = -0.2 * np.sqrt(0.5 * (x[:, 0] ** 2 + x[:, 1] ** 2))
    out = 20. * np.exp(arg1) + 20. + np.e
    out = (out[numpy.newaxis]).T
    return out + noise_L * np.random.randn(out.size, 1)


def Normalize(X, X_m, X_s):
    return (X - X_m) / (X_s)


def train_MFGP(N_H, N_L, Bound):
    # Training data
    lb = Bound[0]
    ub = Bound[1]
    D = lb.size
    X_L = lb + (ub - lb) * lhs(D, N_L)
    X_H = lb + (ub - lb) * lhs(D, N_H)
    # Collect samples
    y_L = f_L(X_L)
    y_H = f_H(X_H)
    model = Multifidelity_GP(X_L, y_L, X_H, y_H)
    model.train()
    return model


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
            print("Round: %d, LF point no.:%d, HF point.no.: %d" % (j + 1, X_L_new.shape[0], X_H_new.shape[0]))
            print("Maximum variance: %f" % (max_var))
            max_var_list[:-1] = max_var_list[1:]
            max_var_list[-1] = max_var
            my_plot_search.plot_var(max_var_list,s)
            s =s +1
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
