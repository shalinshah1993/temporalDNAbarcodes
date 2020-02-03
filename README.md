# ExTemp: A computational and image-processing suite for extracting temporal barcodes

[![GitHub release](https://img.shields.io/github/release/ailiop/idvf.svg)](https://github.com/shalinshah1993/temporalDNAbarcodes/releases/)
[![GitHub license](https://img.shields.io/github/license/shalinshah1993/temporalDNAbarcodes.svg)](https://github.com/ailiop/temporalDNAbarcodes/blob/master/LICENSE)
[![GitHub all releases](https://img.shields.io/github/downloads/shalinshah1993/temporalDNAbarcodes/total.svg)](https://github.com/shalinshah1993/temporalDNAbarcodes/releases/)
![GitHub issues](https://img.shields.io/github/issues/shalinshah1993/temporalDNAbarcodes)

<a name="contents"></a>

## Contents

- [What is ExTemp?](#overview)
- [Software description](#software)
	- [Overview](#software-overview)
	- [Install](#software-install)
	- [Module description](#software-module)
  - [Dependencies](#software-dependencies)
- [License and community guidelines](#license-contrib-reports)
- [System configuration](#system)
- [Contributors](#contributors)
- [Acknowledgements](#acknowledge)

<a name="overview"></a>
This software contains modules that are a part of the temporal DNA barcoding framework. It is a single-molecule imaging technique that uses time-domain to encode information for optical multiplexing. Although, the scripts were developed to our framework, they can be used for any arbitrary microscopy project that requires data extraction from fluorescence microscopy data.

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

A set of MATLAB scripts which can act as pipeline to extract information from the raw image stack. There are several steps involved to extract meaningful information from the recorded raw image stacks. The first step is data-collection \textit{i.e} recording an image stack using TIRF microscope. Once we have the raw data, we convert the proprietary Leica lif file to a mat file using the `bfmatlab` library. This can help us with the development of the programmable downstream MATLAB scripts as the raw data is now available in the supported format. 

The next step includes the estimation and correction of the lateral (x-axis, y-axis) and axial (z-axis) drift. For lateral drift correction, we use the redundant cross-correlation algorithm proposed by `Wang et al. Optics Express (2014)` by incorporating their library within our MATLAB scripts.

Once the drift corrected data stack is available, we apply several filters to locate the localizations and find their centroid coordinates. After extracting the possible set of device coordinates, the temporal intensity time trace is generated assuming the point spread function of 3 X 3 pixels. Once we obtain the intensity time trace for each localization, the next step includes applying the wavelet filter. The filtered temporal barcodes are clustered in two or three states depending on the device using the unsupervised mean shift clustering technique to obtain a state chain. This state chain can be analyzed to extract parameters such as dark-time, on-time, double-blink etc.

<a name="software-install"></a>
### Installation
To use `ExTemp`, simply add its top-level directory to the MATLAB path. All functions are organized in packages. Most modules are stand-alone i.e they take in a file process the intermediate step of pipeline and returns processed output which can act as an input for next sub-step of the pipeline.

For testing purposes, you can download the sample lif file (https://duke.box.com/s/9xy67550rdawj6pk4woqxnyhwknq0n3c) and put it in the /lif/ folder. `sample_date.lif` should be in the lif folder at this point. For example, to convert it to mat, inside MATLAB terminal, type `lif2mat('sample_data.lif')`. Individual modules are described in detail below.

<a name="software-module"></a>
### Module description (sample use)
- `lif2mat`: converts the proprietary Leica file to mat file 
```
life2mat(<file_name>) %this file should be in /lif/ folder, outputs .mat in /tmp/mat/ folder
```

- `findalllocalizations`: find localizations per frame in the entire image stack
```
findalllocalizations(<file_name>) %this video file should be in /video/ folder, outputs in /tmp/all_pnts/ folder
```

- `estdrift`: need localization per frame list to estimate drift using RCC
```
estddrift(<file_name>, <toDisplay>, <segSize>) %this file should be in /tmp/all_pnt/s folder, outputs in /tmp/drft_trc/ folder
```

- `crctdrift`: uses estimated drift trace to apply translational shift
```
crctdrift(<file_name>, <debug>) %this file should be in /tmp/drft_trc/ folder, outputs in /tmp/drft_crct/ folder
```

- `calcdatatrend`: uses input mat image stack file to compute z-drift (or trend)
```
calcdatatrend(<file_name>, <pDegree>) %loads file in /tmp/mat/ folder, outputs in /tmp/calcdatatrend/ folder
```

- `cropmat`: takes a mat image stack and crops each frame it the stack
```
cropmat(<file_name>, <prefix>, <size>) %loads .mat file in /tmp/<prefix>/ folder, outputs in /tmp/crop/ folder
```

- `findlocalizations`: takes an image stack, computes z-projection and finds localization coordinates
```
findlocalizations(<file_name>, <prefix>, <to_display>, <threshold1>, <threshold2>) %loads file in /tmp/<prefix>/ folder, outputs in /tmp/pnts/ folder
```

- `gettemporalbarcode`: computes the temporal barcode for each coordinate in a 3X3 pixel ROI
```
gettemporalbarcode(<file_name>, <prefix>) %loads file in /tmp/<prefix>/ folder, outputs in /tmp/pnts/ folder
```

- `getstatechain`: applies mean shift to denoise temporal barcode into state chain
```
getstatechain(<file_name>, <BW>, <min_on>, <min_db>, <states>) %tloads file in /tmp/pnts/ folder, outputs in /tmp/brcd/ folder
```

- `analyzebarcode`: computes parameters such as on-time, off-time using denoised state chain
```
analyzebarcode(<file_name>, <expTime>) %loads file in /tmp/st_chn/ folder, outputs in /tmp/stats/ folder
```

<a name="software-dependencies"></a>
### Dependencies
- RCC - http://huanglab.ucsf.edu/Resources.html
- bfmatlab - https://docs.openmicroscopy.org/bio-formats/5.3.4/users/matlab/index.html
- meanshift - https://www.mathworks.com/matlabcentral/fileexchange/10161-mean-shift-clustering
- sauvola - https://www.mathworks.com/matlabcentral/fileexchange/40266-sauvola-local-image-thresholding
- Statistics and machine learning toolbox (MATLAB): https://www.mathworks.com/products/statistics.html
- Wavelet toolbox (MATLAB) - https://www.mathworks.com/products/wavelet.html
- Computer vision toolbox (MATLAB) - https://www.mathworks.com/products/computer-vision.html

<a name="license-contrib-reports"></a>

## License and community guidelines

The `ExTemp` code is licensed under the [GNU general public license v3.0](https://github.com/shalinshah1993/temporalDNAbarcodes/blob/master/LICENSE). If you wish to contribute to idvf or report any bugs/issues, please see our [contribution guidelines](https://github.com/shalinshah1993/temporalDNAbarcodes/blob/master/CONTRIBUTING.md) and [code of conduct](https://github.com/shalinshah1993/temporalDNAbarcodes/blob/master/CODE_OF_CONDUCT.md).

[license]: https://github.com/ailiop/idvf/blob/master/LICENSE
[contrib]: https://github.com/ailiop/idvf/blob/master/CONTRIBUTING.md
[conduct]: https://github.com/ailiop/idvf/blob/master/CODE_OF_CONDUCT.md


<a name="system"></a>
## System environment
The `ExTemp` code was developed and tested on MATLAB R2018b. The machine used for development and testing has following config: 10x Tensor TXR231-1000R D126 Intel(R) Xeon(R) CPU E5-2640 v4 @ 2.40GHz (512GB RAM - 40 cores). Note that the use of cluster machine is crucial since most raw data files are several hundreds of gigabytes making it extremely difficult to handle them. Therefore, in order to avoid dealing with memory overflow issue, we use machines with much larger available main memory.

<a name="contributors"></a>
## Contributors
-   *Design, development, testing:*  
    Shalin Shah, and Abhishek Dubey <br>
    Department of Electrical & Computer Engineering, Duke University <br>
    Department of Computer Science, Duke University

-   *Supervision:*  
    John Reif <br>
    Department of Computer Science, Duke University

<a name="acknowledge"></a>
## Acknowledgements
This work was supported by National Science Foundation Grants `CCF-1813805` and `CCF-1617791`.
