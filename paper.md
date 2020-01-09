---
title: 'ExTemp: A computational and image-processing suite for extracting temporal barcodes'
tags:
  - object detection
  - signal processing
  - drift correction
  - object tracking
  - microscopy image analysis
  - computer vision
  - TIRF
  - MATLAB
authors:
  - name: Shalin Shah
    orcid: 0000-0002-1406-3577
    affiliation: 1
  - name: Abhishek Dubey
    orcid: 0000-0001-8052-7416
    affiliation: "1, 3"
  - name: John Reif
    affiliation: "1, 2"
affiliations:
  - name: Department of Electrical & Computer Engineering, Duke University, Durham, NC 27708, USA
    index: 1
  - name: Department of Computer Science, Duke University, Durham, NC 27708, USA
    index: 2
  - name: Computational Sciences and Engineering Division, Health Data Sciences Institute, Oak Ridge National Lab, Oak Ridge, Tennessee 37831, United States
    index: 3
date: 9 January 2020
bibliography: references.bib
---


# Summary

We provide a package for fast and accurate extraction of temporal barcodes from a stack of microscopy images. This includes several steps such as object detection and tracking, 3D drift detection and correction, signal processing and denoising, and barcode extraction. A temporal barcode [@shah2019improved] is defined as the intensity trace over time of an object of interest. In particular, since the fluorescent signal comes from dye-labeled DNA, hence temporal DNA barcodes. To our knowledge, no other package can perform systematic extraction of time signals from microscopy images. The relevant application includes improved optical multiplexing and super-resolution imaging.

``ExTemp`` is a set of MATLAB scripts that can act as computer vision pipeline to extract relevant information from the raw image stack. There are several steps involved to extract meaningful information from the recorded raw image stacks [@shah2019programming]. The first step includes data-collection \textit{i.e} recording a video (or an image stack) using a TIRF microscope. Once we have the raw data (usually several gigabytes), we convert the proprietary Leica lif file to a mat file using the bfmatlab library. This can help us with the development of the programmable downstream MATLAB scripts as the raw data is now available in the supported format. The next step includes the estimation and correction of the lateral (x-axis, y-axis) and axial (z-axis) drift. For lateral drift correction, we use the redundant cross-correlation algorithm [@wang2014localization] and for axial drift correction, we subtract mean pixel value of each frame.

Once the drift corrected data stack is available, our algorithm applies several signal processing filters[@shah2019programming] to locate the localizations and find their centroid coordinates. After extracting the possible set of device coordinates, the temporal intensity time trace is generated assuming the point spread function of 3 X 3 pixels. Once we obtain the intensity time trace for each localization, the next step includes applying the wavelet filter. The filtered temporal barcodes are clustered in two or three states depending on the device using the unsupervised mean shift clustering technique to obtain a state chain. This state chain can be analyzed to extract parameters such as dark-time, on-time, double-blink, etc.

A pre-release version of ``ExTemp`` has been used in scientific publications to demonstrate the computational pipeline, signal processing [@shah2019programming] and potential applications [@shah2018temporal].  The ``ExTemp`` package is implemented in MATLAB.


# References
