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
import sys


np.random.seed(1234)


def init_MFGP():
    """
    Note that all hyperparams are log-scaled, and
        hyp[0] = mu_lo
        hyp[1] = s^2_lo
        hyp[2] = l_lo
        hyp[3] = mu_hi
        hyp[4] = s^2_hi
        hyp[5] = l_hi
        hyp[6] = rho
        hyp[7] = noise l
        hyp[8] = noise h
    """
    X_L = np.empty([0, 2])
    y_L = np.empty([0, 1])
    X_H = np.empty([0, 2])
    y_H = np.empty([0, 1])
    model = Multifidelity_GP(X_L, y_L, X_H, y_H)
    model.hyp = numpy.loadtxt('cov_hyp.txt')
    return model


def update_MFGP_L(model, X_Lmem, y_Lmem):
    # Update interface with matlab
    # Convert to numpy from memoryview objects passed by matlab
    X_L = np.asarray(X_Lmem)
    y_L = np.asarray(y_Lmem)
    X_H = model.X_H
    y_H = model.y_H

    # Reshape to n by 1 vectors
    y_L = y_L[:, None]
    #y_H = y_H[:, None]
    
    # Update model
    model.updt_info(X_L, y_L, X_H, y_H)
    return model


def update_MFGP_H(model, X_Hmem, y_Hmem):
    # Update interface with matlab
    # Convert to numpy from memoryview objects passed by matlab
    X_H = np.asarray(X_Hmem)
    y_H = np.asarray(y_Hmem)
    X_L = model.X_L
    y_L = model.y_L

    # Reshape to n by 1 vectors
    #y_L = y_L[:, None]
    y_H = y_H[:, None]
    
    # Update model
    model.updt_info(X_L, y_L, X_H, y_H)
    return model


def predict_MFGP(model, X_star):
    # Prediction interface with matlab

    # Predict given test points
    pred_u_star, var_u_star = model.predict(X_star)

    u = pred_u_star.squeeze()
    var = np.abs(np.diag(var_u_star.squeeze()))

    return [u, var]


def test_func(arg):
    array = np.asarray(arg)
    print(array)


if __name__ == "__main__":

    # train hyperparameters from CSV file
    # store LoFi points in lofi.csv
    # store HiFi points in hifi.csv
    # return new hyperparameters and save in cov_hyp.txt if valid

    lofi = numpy.loadtxt('lofi.csv', skiprows=1, delimiter=',')
    hifi = numpy.loadtxt('hifi.csv', skiprows=1, delimiter=',')

    X_L = lofi[:, 0:2].reshape(-1, 2)      # columns 1 and 2 are (x,y) points
    y_L = lofi[:, 2].reshape(-1, 1)        # column 3 is f(x,y)
    X_H = hifi[:, 0:2].reshape(-1, 2)
    y_H = hifi[:, 2].reshape(-1, 1)

    model = Multifidelity_GP(X_L, y_L, X_H, y_H)
    model.train()
    print(model.hyp);

    fname = input("Filename to save hyperparameters to: ")
    np.savetxt(fname, model.hyp, delimiter='\n')
