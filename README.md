# ExTemp: A computational and image-processing suite for extracting temporal barcodes

[![GitHub release](https://img.shields.io/github/release/ailiop/idvf.svg)](https://github.com/shalinshah1993/temporalDNAbarcodes/releases/)
[![GitHub license](https://img.shields.io/github/license/shalinshah1993/temporalDNAbarcodes.svg)](https://github.com/ailiop/temporalDNAbarcodes/blob/master/LICENSE)
[![GitHub all releases](https://img.shields.io/github/downloads/shalinshah1993/temporalDNAbarcodes/total.svg)](https://github.com/shalinshah1993/temporalDNAbarcodes/releases/)
![GitHub issues](https://img.shields.io/github/issues/shalinshah1993/temporalDNAbarcodes)

<a name="contents"></a>

## Contents

- [Overview](#overview)
- [Software description](#software)
	- [Overview](#software-overview)
	- [Module description](#software-module)
  - [Dependencies](#software-dependencies)
- [License and community guidelines](#license-contrib-reports)
- [Contributors](#contributors)

<a name="overview"></a>
These software scripts are a part of the temporal DNA barcoding framework. It is a single-molecule imaging techqniue that uses time-domain to encode information for optical multiplexing. Although, the scripts were developed to our framework, they can be used for any arbitrary project that requires data extraction from fluorescence microscopy data.

If you find our suite helpful, please cite our paper(s):

`Shalin Shah, Abhishek Dubey, and John Reif. "Programming temporal DNA barcodes for single-molecule fingerprinting". Nano Letters (2019) DOI: 10.1021/acs.nanolett.9b00590` [[PDF]](https://pubs.acs.org/doi/10.1021/acs.nanolett.9b00590)

`Shalin Shah, Abhishek Dubey, and John Reif. "Improved optical multiplexing with temporal DNA barcodes". ACS Synthetic Biology (2019) DOI: 10.1021/acssynbio.9b00010` [[PDF]](https://pubs.acs.org/doi/10.1021/acssynbio.9b00010)

`Shalin Shah, and John Reif. "Temporal DNA Barcodes: A Time-Based Approach for Single-Molecule Imaging." International Conference on DNA Computing and Molecular Programming. Springer, Cham, 2018. DOI: 10.1007/978-3-030-00030-1_5` [[PDF]](https://link.springer.com/content/pdf/10.1007%2F978-3-030-00030-1_5.pdf)

<a name="software"></a>
## Information extraction scripts
| ![Computer vision pipeline](https://github.com/shalinshah1993/temporalDNAbarcodes/blob/master/PIPELINE.png) | 
|:--:| 
| *A visual depiction of the computer vision pipeline/ algorithm. The figure is adapted with permission from `Shalin Shah, Abhishek K. Dubey, and John Reif, "Programming Temporal DNA Barcodes for Single-Molecule Fingerprinting." Nano Letters 2019 19 (4), 2668-2673.` Copyright 2019 American Chemical Society* |

<a name="software-overview"></a>

A set of Matlab scripts which can act as pipeline to extract information from the raw image stack. There are several steps involved to extract meaningful information from the recorded raw image stacks. The first step is data-collection \textit{i.e} recording an image stack using TIRF microscope. Once we have the raw data, we convert the proprietary Leica lif file to a mat file using the `bfmatlab` library. This can help us with the development of the programmable downstream MATLAB scripts as the raw data is now available in the supported format. 

The next step includes the estimation and correction of the lateral (x, y-direction) and axial (z-direction) drift. For lateral drift correction, we use the redundant cross-correlation algorithm proposed by `Wang et al. Optics Express (2014)` by incorporating their library within our MATLAB scripts.

Once the drift corrected data stack is available, we apply several filters to locate the localizations and find their centroid coordinates. After extracting the possible set of device coordinates, the temporal intensity time trace is generated assuming the point spread function of 3 X 3 pixels. Once we obtain the intensity time trace for each localization, the next step includes applying the wavelet filter. The filtered temporal barcodes are clustered in two or three states depending on the device using the unsupervised mean shift clustering technique to obtain a state chain. This state chain can be analyzed to extract parameters such as dark-time, on-time, double-blink etc.

<a name="software-module"></a>
### Module description
- `lif2mat`: converts the proprietary Leica file to mat file 
- `findalllocalizations`: find localizations per frame in the entire image stack
- `estdrift`: need localization per frame list to estimate drift using RCC
- `crctdrift`: uses estimated drift trace to apply translational shift
- `calcdatatrend`: uses input mat image stack file to compute z-drift (or trend)
- `cropmat`: takes a mat image stack and crops each frame it the stack
- `findlocalizations`: takes an image stack, computes z-projection and finds localization coordinates
- `gettemporalbarcode`: computes the temporal barcode for each coordinate in a 3X3 pixel ROI
- `getstatechain`: applies mean shift to denoise temporal barcode into state chain
- `analyzebarcode`: computes parameters such as on-time, off-time using denoised state chain

<a name="software-dependencies"></a>
### Dependencies
- RCC - http://huanglab.ucsf.edu/Resources.html
- bfmatlab - https://docs.openmicroscopy.org/bio-formats/5.3.4/users/matlab/index.html
- meanshift - https://www.mathworks.com/matlabcentral/fileexchange/10161-mean-shift-clustering
- sauvola - https://www.mathworks.com/matlabcentral/fileexchange/40266-sauvola-local-image-thresholding

<a name="license-contrib-reports"></a>

## License and community guidelines

The `ExTemp` code is licensed under the [GNU general public licensev3.0][license]. If you wish to contribute to idvf or report any bugs/issues, please see our [contribution guidelines][contrib] and [code of conduct][conduct].

[license]: https://github.com/ailiop/idvf/blob/master/LICENSE
[contrib]: https://github.com/ailiop/idvf/blob/master/CONTRIBUTING.md
[conduct]: https://github.com/ailiop/idvf/blob/master/CODE_OF_CONDUCT.md


<a name="contributors"></a>

## Contributors
-   *Design, development, testing:*  
    Shalin Shah, and Abhishek Dubey
    Department of Electrical & Computer Engineering, Duke University
    Department of Computer Science, Duke University

-   *Supervision:*  
    John Reif
    Department of Computer Science, Duke University
