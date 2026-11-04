# Advanced parameters and result interpretation — MATLAB

Return to the [README](../README.md).

The numerical functions `sFRC`, `sFSC` and `srFRC` are in `src/`. The three MATLAB demos are in `demos/`; plotting and export helpers are in `src/Utils/`. The numerical functions return results without creating figures or files.

Go directly to the analysis you are using:

- [sFRC — global 2D resolution](#sfrc)
- [sFSC — lateral/axial 3D resolution and DRI](#sfsc)
- [srFRC — local resolution maps](#srfrc)
- [Demo outputs](#demo-outputs)

Use the original acquisition calibration. **Enter `pixelSize` in µm; reported resolutions and srFRC map values are in nm.** For example, 60 nm is `0.06` µm. A 2D stack uses `(Y,X,T)`; an sFSC volume uses `(Y,X,Z)` with voxel spacing `[x,y,z]`. DRI angles are in **radians**.

## How to interpret the results

| Output | Interpretation |
| --- | --- |
| Resolution (nm) | **Smaller** values indicate finer estimated resolvable detail; compare results with appropriate calibration and consistent settings. |
| `NaN` / unavailable | No usable estimate was obtained. Check warnings, sampling and correlation curves; do not interpret it as zero. |
| srFRC map value `0` | Background or an invalid local estimate, **not** a measured resolution of 0 nm. Background zeros are excluded from foreground statistics. |
| `E_DRI` (sFSC) | Agreement between directional cutoffs and the DRI model; **not** an error against ground truth or a confidence interval. |

Background **intensity thresholds** use a 0–255 scale and are separate from FRC/FSC **correlation thresholds**. Use numerical results and Float32 TIFF/MAT files for quantitative analysis rather than relying on map colours.

| `batchProcessing` | Computation | Demo display |
| --- | --- | --- |
| `true` (default) | All frames or adjacent pairs | First frame/pair only |
| `false` | First frame or first adjacent pair only | That result only |

The numerical functions do not accept `currentFrame`, `plotMode` or a general plotting switch. The demos show only the first frame/pair, regardless of batching. For srFRC, `monitorChange=true` overrides Batch and compares different background settings on the first frame/pair. sFSC analyzes a 3D volume or volume pair, not a time-stack batch.

## sFRC

Global resolution estimation for 2D images and image stacks.

### sFRC input and calibration

Use one `(Y,X)` image or `(Y,X,T)` stack. In paired mode, adjacent frames are compared.

### sFRC parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| `pixelSize` | `0.02` | XY spacing in **µm**; replace with the acquisition value |
| `singleFrame` | `true` | Generate a diagonal pair from each frame; `false` uses adjacent frames |
| `threshold` | `'1/7 hard threshold'` | Alternative: `'3-sigma'` |
| `meanFilterWidth` | `3` | Correlation smoothing radius in frequency bins |
| `batchProcessing` | `true` | Process every frame or adjacent pair |
| `motionCorrection` | `false` | Align paired frames before analysis |

### sFRC curve extrapolation

Resolution normally comes from a measured correlation-threshold crossing. If none is available, the fixed 1/7 criterion permits automatic extrapolation; Extrapolation extends beyond the measured frequencies and adds no new measured information.

Extrapolation is not a public option. The function reports attempts and warnings; an unavailable estimate remains `NaN`. The selected threshold is never silently changed.

### sFRC stack batching and plotting

With `batchProcessing=true`, an N-frame stack produces N single-frame results or N−1 overlapping adjacent-pair results. With `false`, only the first frame or pair `(1,2)` is analyzed.

The demo plots only the first result. Numerical exports retain all computed frames/pairs.

### sFRC results and saved files

The summary records the frame/pair, threshold, extrapolation status and resolution in nm.

| Content | Filename examples |
| --- | --- |
| Summary and numerical results | `sFRC_results.csv`, `sFRC_results.mat` |
| Optional curve preview | `sFRC_frame0001_correlation-curve.png` |

## sFSC

Lateral and axial resolution estimation for 3D volumes using DRI.

### sFSC input and calibration

Use a `(Y,X,Z)` volume or two matching volumes. Paired inputs can also be supplied as `(Y,X,Z,2)`. Enter voxel spacing as `pixelSize=[x y z]` in **µm**. DRI angles are measured from the XY plane in **radians**.

### sFSC parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| `pixelSize` | `[0.03 0.03 0.1]` | Voxel spacing `[x y z]` in µm; replace with acquisition values |
| `zSampling` | `false` | Optionally use complementary odd/even Z planes |
| `lowAngle` | `pi/12` | Lower DRI angle; recommended `>pi/18` |
| `highAngle` | `pi/3` | Upper DRI angle; recommended `<4*pi/9` |
| `numCones` | `5` | Number of directional cones; at least 5 is recommended |
| `singleFrame` | `true` | Generate a resampled pair from one volume |
| `threshold` | `'1/7 hard threshold'` | Alternative: `'3-sigma'` |
| `meanFilterWidth` | `3` | Correlation smoothing radius in frequency bins |
| `xyMode` | `'slice'` | Optionally choose `'3D'` for low-SNR data |
| `motionCorrection` | `false` | Align paired volumes |
| `progress` | `true` | Show computation progress |

### sFSC curve extrapolation

Measured crossings are preferred. Automatic extrapolation is available only for the fixed 1/7 threshold. During DRI, directional extrapolation is attempted **only if no direction has a usable measured crossing**; otherwise, fitting uses the available measured directions.

An unsuccessful estimate remains `NaN` with a warning. The result records whether extrapolation was attempted, which does not necessarily mean it succeeded.

### E_DRI: what the value means

DRI fits a directional frequency-support model. E_DRI is the cosine-weighted relative RMS fitting error:

$$
E_{\mathrm{DRI}}=
\sqrt{\frac{\sum_i\cos\theta_i
[(k_i-k_{\mathrm{fit},i})/k_{\mathrm{fit},i}]^2}
{\sum_i\cos\theta_i}}.
$$

Here, `θ` is measured from the XY plane, `k_i` is a measured directional cutoff, and `k_fit,i` is the fitted value. E_DRI measures model consistency, not ground-truth accuracy.

| E_DRI (%) | Interpretation |
| --- | --- |
| `<10%` | Reliable under the DRI consistency criterion |
| `10–20%` | Use with caution |
| `>20%` | Unacceptable; do not accept the axial estimate |
| `NaN` / unavailable | No fit-error assessment |

For `E_DRI ≥10%`, inspect directional curves and consider adjusting the fitting angles. Recommended limits are `lowAngle > pi/18` and `highAngle < 4*pi/9`. A low E_DRI alone does not guarantee a correct estimate.

`Z.E_DRI` is a fraction (`0.10` means 10%); `Z.summary.E_DRI_percent` is already a percentage.

### Z sampling: manual control and axial interpretation

`zSampling` is **false by default** and is never enabled automatically. It uses complementary odd/even Z planes for axial analysis, which can reduce shared inter-plane correlations but also reduces axial sampling density.

If the axial estimate appears implausibly small, enable it manually and compare the axial resolution, directional crossings and E_DRI.

```matlab
[XY,Z] = sFSC(volume, 'pixelSize', [0.02 0.02 0.06], ...
    'zSampling', true, 'lowAngle', pi/12, 'highAngle', pi/3);
```

### Warnings and prompts

| Situation | MATLAB behavior |
| --- | --- |
| Missing crossing or failed extrapolation | Warning; unavailable estimate remains `NaN` |
| Unusable DRI fit | DRI-specific warning |
| `E_DRI ≥10%` | Interpretation and fitting-angle advice |
| Angles outside recommended limits | Warning; input angles remain unchanged |
| Single-frame axial result with Z sampling OFF | Conditional interpretation note |

The Command Window reports warnings and the E_DRI grading guide. The sFSC demo displays the available resolution profile; its separate `plotFittingCurve` demo setting controls an optional DRI-fit figure.

### sFSC results and saved files

The summary reports lateral/axial resolution (nm), E_DRI (%) and extrapolation status.

| Content | Filename examples |
| --- | --- |
| Summary / numerical results | `sFSC_results.csv`, `sFSC_results.mat` |
| Interpretation | `sFSC_E-DRI-guidance.txt` |
| Resolution preview | `sFSC_lateral-axial-resolution.png` |
| Optional fitting preview | `sFSC_DRI-elliptical-fit.png` |

## srFRC

Spatially resolved local-resolution maps for 2D images and stacks.

### srFRC input and calibration

Use `(Y,X)` or `(Y,X,T)`. Supply the original scalar XY `pixelSize` in **µm**. In paired mode, adjacent frames are compared.

### srFRC parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| `pixelSize` | `0.02` | XY spacing in µm; replace with the acquisition value |
| `singleFrame` | `true` | Generate a diagonal pair per frame; `false` uses adjacent frames |
| `threshold` | `'3-sigma'` | Alternative: `'1/7 hard threshold'` |
| `batchProcessing` | `true` | Process all frames/pairs |
| `motionCorrection` | `false` | Align paired frames |
| `blocksize` | `64` | Local window width in pixels |
| `skip` | `2` | Step between analysis windows in pixels |
| `adaptiveBackground` | `true` | Automatic Otsu-based background detection |
| `monitorChange` | `false` | Compare different Otsu coefficients on the first frame/pair; disable Batch |
| `backgroundIntensity` | `30` | Manual background threshold (0–255) when automatic/monitor modes are off |
| `parallel` | `true` | Use parallel computation when available |
| `meanFilterWidth` | `3` | Local correlation smoothing radius |
| `boundary` | `true` | Apply background masking |
| `amedianfilter` | `true` | Adaptive median filtering when `skip=1` |

The selected `threshold` is the primary local criterion; internal fallback criteria are not additional user choices. Local curves are not extrapolated.

### srFRC background settings

`monitorChange=true` compares background thresholds using different Otsu coefficients on the first frame/pair and disables Batch. Otherwise, use automatic background detection or set `backgroundIntensity` manually.

### srFRC stack batching and plotting

With `batchProcessing=true`, an N-frame stack produces N single-frame results or N−1 adjacent-pair results. With `false`, only the first frame or pair is analyzed. The demo displays only the first result; Monitor displays its background comparisons.

Numeric maps and summary tables retain every computed frame/pair.

### srFRC results and saved files

Summaries report the frame/pair, background setting and actual threshold, mean/min/max resolution (nm), and rFRC value. Statistics exclude zero-background pixels.

| Content | Filename examples |
| --- | --- |
| Summary / numerical results | `srFRC_results.csv`, `srFRC_results.mat` |
| Numerical maps | Separate Float32 TIFF files for each background setting |
| Optional preview | First-frame resolution-map PNG |

## Demo outputs

The three `.m` demos read from `example_data/` and save into the current working directory's `results/` folder when `saveResults` is enabled. Core numerical functions neither plot nor save.

| Demo | Purpose |
| --- | --- |
| `sFRC_demo.m` | Single-frame and paired-frame resolution analysis |
| `sFSC_demo.m` | 3D lateral/axial resolution and DRI; optional Z-sampling comparison |
| `srFRC_demo.m` | Background selection, batch processing and local maps |

Plotting and export utilities are in `src/Utils/`. Re-running a demo may overwrite files with the same name.
