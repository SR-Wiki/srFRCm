# Advanced parameters and result interpretation — MATLAB

Return to the [README](../README.md).

This guide applies to this MATLAB repository. The numerical entry points are
`sFRC`, `sFSC`, and `srFRC` in `src/`. They accept image arrays and return
numerical results. The three `.m` demos in `demos/` read example TIFF files; numerical and
display/export helpers are in `src/Utils/`. The core functions do not create
files or figures. Run demos from MATLAB after adding the repository paths.

## Find the function you need

| Function | Input | Output |
| --- | --- | --- |
| `sFRC` | 2D image or `(Y,X,T)` stack | Global 2D resolution in nm for each analyzed frame/pair |
| `sFSC` | `(Y,X,Z)` volume; paired volumes supported | Lateral/axial resolution in nm and E_DRI (%) |
| `srFRC` | 2D image or `(Y,X,T)` stack | Local resolution maps (nm), foreground statistics and background thresholds |

**Units:** MATLAB `pixelSize` is entered in **µm**, but all reported resolution
values and map values are in **nm**. Example: 60 nm corresponds to `0.06` µm.
MATLAB `sFSC` voxel spacing is `[x,y,z]` and DRI angles are in **radians**.
Use your acquisition calibration rather than relying on demonstration defaults.

## How to interpret the results

| Output | Interpretation |
| --- | --- |
| Resolution (nm) | **Smaller** values indicate finer estimated resolvable detail; compare results obtained with appropriate sampling and the same analysis settings. |
| `NaN` / unavailable | No usable resolution estimate was obtained; check warnings, pixel/voxel spacing and the correlation curves instead of treating it as zero. |
| srFRC map value `0` | Background or an invalid local estimate, **not** a measured resolution of 0 nm. Zero pixels are excluded from foreground resolution statistics. |
| `E_DRI` (sFSC) | Agreement between directional cutoffs and the fitted DRI model. **Not** an error relative to ground truth or a confidence interval. |

For srFRC, background **intensity thresholds** (0–255 scale) are separate from
FRC/FSC **correlation thresholds** (`1/7 hard threshold` and `3-sigma`).
Numerical map values are in nm; colour rendering is for inspection and should
not replace quantitative TIFF/MAT/NPZ data.


## Threshold choices and batch preview

The only public FRC/FSC correlation thresholds are `1/7 hard threshold` and
`3-sigma`. sFRC/sFSC default to 1/7; srFRC defaults to `3-sigma`.
`'1/7'` and `'fixed_threshold'` remain accepted aliases for the fixed 1/7
criterion; internal 2-/5-sigma fallbacks for srFRC are not selectable settings.

**Batch controls calculation, not which result is displayed.** MATLAB displays
the **first** analyzed frame or adjacent frame pair; there is **no**
`currentFrame`, `plotMode`, or numerical-function plot argument.

| Setting | Computation | Demo preview |
| --- | --- | --- |
| `batchProcessing=true` | All frames or adjacent pairs | First frame/pair only |
| `batchProcessing=false` | First frame or first adjacent pair | That result only |
| `monitorChange=true` (srFRC) | Forces batch OFF; three background groups on first frame/pair | All three backgrounds for the first frame/pair |

The sFRC/srFRC demos display one result and use `saveResults` only to control
export. sFSC treats the volume as one dataset; `plotFittingCurve` requests an
additional fitting figure. To analyze a different time point, pass the desired
frame or substack as a new input array.

## Input precision, normalization and plot appearance

TIFF readers used by the demos convert each page directly to **single (float32)** and
divide the complete loaded stack by its maximum. The three numerical entry points also prepare
direct image-array inputs as single and normalize by the maximum before
diagonal averaging or motion correction. An all-zero input remains zero;
non-finite intensities produce an explanatory error. Input arrays are not
modified, and there is no intermediate 8-bit/16-bit image conversion.

The reading/preparation stage is 32-bit floating point; subsequent FFT, fitting
or interpolation routines may retain their existing higher calculation precision.

One maximum is shared by a complete stack or 3D volume, preserving relative
slice intensities. Each acquisition in paired sFSC is normalized independently,
whether supplied as two arguments or as a fourth-dimension pair. srFRC also
normalizes each generated pair member to a maximum of one. Its manual and
reported background thresholds retain their **0-255 units**: background tests
use threshold/255, and only the temporary Otsu histogram image is quantized to
uint8. Correlation calculations continue to use floating-point image data.

Figures retain numerical results such as E_DRI but omit grades, warnings,
fitting-angle advice, extrapolation notices and Z-sampling reminders. Those
diagnostics remain in the Command Window, with existing text/MAT exports
retained. Correlation curves, the fitted 3D anisotropic resolution profile and
DRI-fit lines use light red **[230 115 115]/255**. Measured-point markers and
threshold lines retain contrasting colours. Display/export remains in demo
utilities; the numerical functions have no plotting or file-output parameters.

## Parameter names and defaults

Use the original acquisition calibration. Input sampling is in **um**;
reported resolutions and srFRC map values are in **nm**.

| Input | Array order / calibration |
| --- | --- |
| sFRC/srFRC image or stack | `(Y,X)` or `(Y,X,T)`; scalar `pixelSize` in um |
| sFSC volume | `(Y,X,Z)`; `pixelSize=[x y z]` in um |
| Paired sFSC input | Two volume arguments, or one `(Y,X,Z,2)` array |
| DRI fitting angles | Radians, measured from the XY plane |

The following sFSC controls are listed with the axial/DRI settings first.

| Parameter | Default | Meaning |
| --- | --- | --- |
| `zSampling` | `false` | Manually enable complementary odd/even Z-plane sampling |
| `lowAngle` | `pi/12` | Lower DRI angle, 15 degrees; recommended `>pi/18` |
| `highAngle` | `pi/3` | Upper DRI angle, 60 degrees; recommended `<4*pi/9` |
| `numCones` | `5` | Positive integer directional-cone count; at least 5 is recommended |
| `singleFrame` | `true` | Generate an XY-resampled pair from one volume |
| `threshold` | `'1/7'` | sFRC/sFSC threshold; `'3-sigma'` is also supported |
| `meanFilterWidth` | `3` | Correlation smoothing radius in frequency bins |
| `xyMode` | `'slice'` | Optionally set `'3D'` for low-SNR data |
| `motionCorrection` | `false` | Align paired inputs; not used for single-frame pair generation |
| `progress` | `true` | Display sFSC progress bars |

sFRC/srFRC default to `singleFrame=true`, `batchProcessing=true`,
and `motionCorrection=false`. Their `pixelSize` default is
`0.02` µm; replace it with the calibrated spacing. sFSC has a default
`pixelSize=[0.03 0.03 0.1]` µm, which also needs acquisition-specific calibration.

| srFRC parameter | Default | Meaning |
| --- | --- | --- |
| `threshold` | `'3-sigma'` | Only alternative: `'1/7 hard threshold'` (or its alias `'1/7'`) |
| `blocksize` | `64` | Local window width; rounded up to an even integer |
| `skip` | `2` | Rolling step, capped at half the window width |
| `adaptiveBackground` | `true` | Use 1.2 times Otsu; forced false by monitorChange |
| `monitorChange` | `false` | Compare Otsu multipliers 0.8, 1.0, and 1.2; takes priority |
| `backgroundIntensity` | `30` | Manual 0–255 intensity threshold, used only when both background switches are false |
| `parallel` | `true` | Use parallel processing when the toolbox is available; otherwise serial |
| `meanFilterWidth` | `3` | Local correlation smoothing radius |
| `boundary` | `true` | Apply the local background-intensity mask |
| `amedianfilter` | `true` | Apply the adaptive median filter when `skip=1` |

srFRC exposes `threshold`, defaulting to `'3-sigma'`; the only other criterion is
`'1/7 hard threshold'`. The same selection is used in serial and parallel work,
with the existing calibrated 5-sigma/2-sigma fallbacks and no local-curve extrapolation. For sFRC/sFSC,
`curve_extrapolation` describes an automatic fallback, not a public option.
`E_DRI` is an output diagnostic.

## Curve extrapolation

Resolution uses a crossing between the measured correlation curve and its
threshold. Extrapolation fits a curve beyond the measured frequency range
when no usable crossing is available; it does not add measured information.

1. sFRC and lateral sFSC use measured crossings when available. Otherwise,
   automatic extrapolation is attempted for the `'1/7'` threshold.
2. Axial sFSC/DRI first evaluates every directional curve without extrapolation.
   If any direction has a usable measured crossing, only usable measured
   directions enter the fit. Missing directions are excluded.
3. Directional extrapolation is attempted only when **all directions lack
   usable measured crossings**, and only for `'1/7'`.
4. Failed extrapolation, an unsupported threshold, or an unusable fit leaves
   unavailable estimates as `NaN` and issues a warning. An unavailable lateral
   anchor also prevents an axial estimate.

Successful extrapolation prints a stage-specific notice with `fprintf`.
Failure and unsupported thresholds use `warning(...)`; the selected threshold
is never silently changed. Internal measured-only controls support the first
DRI pass and rolling FRC and are not public switches.

The summaries record `extrapolation_triggered` as an attempt flag, including
failed attempts. sFSC also records `extrapolation_stage`: `none`, `lateral`,
`axial`, or `lateral and axial`. Lateral tracking includes candidate slices;
the flag alone does not prove that the final selected curve was extrapolated.
Inspect the notices and returned curve/fit information.

## E_DRI: what the value means

DRI fits an elliptical frequency model using the lateral anchor and selected
directional cutoffs. E_DRI is the cosine-weighted relative RMS fitting error:

$$
E_{\mathrm{DRI}}=
\sqrt{\frac{\sum_i\cos\theta_i
[(k_i-k_{\mathrm{fit},i})/k_{\mathrm{fit},i}]^2}
{\sum_i\cos\theta_i}}.
$$

Here, `theta` is measured from the XY plane, `k_i` is a directional cutoff
used in the fit, and `k_fit,i` is predicted by the fitted ellipse. This checks
model consistency; it is not a ground-truth resolution error or confidence
interval. Few usable directions or an incorrect calibration can still make a
low-error result unreliable.

| E_DRI in percent | Interpretation |
| --- | --- |
| `<10%` | Reliable under the DRI consistency criterion |
| `10–20%`, including exactly 10% and 20% | Use with caution |
| `>20%` | Unacceptable; do not accept the axial estimate |
| Unavailable / `NaN` | No fit-error assessment; no reliability grade |

For finite `E_DRI >=10%`, the warning recommends adjusting the DRI fitting
angle range and repeating the analysis. Recommended limits are
**lowAngle >10 degrees** and **highAngle <80 degrees**. Since the function
takes radians, use **`lowAngle >pi/18`** and **`highAngle <4*pi/9`**.

Valid bounds are `0 <= lowAngle < highAngle <=pi/2`. Recommended angle limits
produce advice, not automatic setting changes. `numCones` must be a positive
integer; values below 5 remain accepted. Choose angles from directional curve
quality and sampling, rather than minimizing E_DRI alone.

`Z.E_DRI` is a fraction: `0.10` means 10%. `Z.summary.E_DRI_percent` is
already in percent. Estimates above 20% remain available for inspection and
export together with their warning; export does not make them acceptable.

## Z sampling: manual control and axial interpretation

`zSampling` is **false by default** and must be enabled manually. Voxel
spacing, anisotropy, and estimated resolution never enable it automatically.

When enabled, the axial stage uses complementary odd/even Z planes from the
working volumes and doubles the effective Z spacing. This can reduce shared
axial correlations associated with adjacent planes and inter-plane
inconsistencies. It also reduces sampling density and may change directional
crossings and the inferred result. It is separate from spacing-matching
preprocessing and from srFRC cubic-spline map restoration.

If axial resolution seems implausibly small for the acquisition, enable
`zSampling`, rerun, and compare the axial estimate, directional crossings and
E_DRI. The code does not automatically classify an estimate as optimistic.
A finite single-frame axial result with Z sampling OFF receives a conditional
interpretation note.

```matlab
% volume is an already loaded (Y,X,Z) array; spacing is [x y z] in um.
[XY,Z] = sFSC(volume, 'pixelSize', [0.02 0.02 0.06], ...
             'zSampling', true, 'lowAngle', pi/12, 'highAngle', pi/3);
```

The selected setting is returned in `Z.zSamplingEnabled` and `Z.parameters`.
The conditional note is returned in `Z.interpretationNote`.

## Warnings and prompts

| Situation | MATLAB behavior |
| --- | --- |
| Extrapolation succeeds | Stage-specific `fprintf` notice |
| Missing crossing or failed/unsupported extrapolation | `warning(...)`; unavailable estimate remains `NaN` |
| No usable directional crossing or invalid DRI fit | DRI-specific warning, including `sFSC:DRINoCrossing` |
| Finite E_DRI >=10% | `sFSC:DRIGoodnessOfFit` warning with grading and fitting-angle advice |
| `lowAngle <=pi/18` or `highAngle >=4*pi/9` | `sFSC:FittingAngleRange` warning explaining the radians convention |
| Single-frame axial estimate, Z sampling OFF | Conditional console note and `Z.interpretationNote` |

Optional sFSC figures contain numerical E_DRI values without interpretation
or advice. The Command Window retains all diagnostics. The demo also retains
grading and axial notes in numerical-result metadata and a guidance text file.

## Complete grading guide on every sFSC exit

Every public sFSC call appends this guide to the console when it exits:

```text
E_DRI (relative fit error): <10% reliable; 10-20% use with caution; >20% unacceptable.
```

The `onCleanup` notice also applies to unavailable crossings, failed fits,
early returns, and parameter/runtime errors. It is independent of plotting
and of whether E_DRI is high. An unavailable value receives no grade. The
guide stays in textual output rather than adding repetitive CSV columns.

## Stack batching and plotting

sFRC/srFRC accept `(Y,X,T)` stacks. With `batchProcessing=true`, a stack with
N frames produces N single-frame results or N−1 consecutive paired results
`(1,2), (2,3), ..., (N−1,N)`. With `batchProcessing=false`, only the first
frame or pair `(1,2)` is analyzed. At least two frames are needed for paired
mode.

There is no optional frame-selection parameter. Regardless of batch mode,
plot helpers show only the **first** computed frame/pair (and, for monitored
srFRC, its three background maps). Results tables and numerical files retain
all frames that were actually computed. sFSC uses a 3D volume or volume pair
and does not use 2D-stack batching.

Display and saving remain separate demo operations; the numerical entry points
have no plot or file-output switches. The sFSC demo always plots its available
resolution profile, with `plotFittingCurve=false` controlling only the optional
additional fit diagnostic.

## srFRC background parameter relationships

`monitorChange=true` takes priority: it forces **both**
`adaptiveBackground=false` and `batchProcessing=false`. The first frame/pair
is evaluated with three Otsu multipliers; this is not the manual-background
mode.

| monitorChange | adaptiveBackground (effective) | Background thresholds | backgroundIntensity |
| --- | --- | --- | --- |
| `true` | `false`, forced | `0.8 x Otsu`, `1.0 x Otsu`, `1.2 x Otsu` | Ignored |
| `false` | `true` | `1.2 x Otsu` | Ignored |
| `false` | `false` | Fixed manual value | Used, default `30` |

Both requested values of adaptiveBackground produce the same three comparisons
when monitorChange is true. A Command Window notice explains the override;
`result.parameters` records the effective false value. The three background
settings remain separate along the map's B dimension and in per-frame summary rows.
Otsu is evaluated for each working image pair. Manual and final reported thresholds
use the **0-255 intensity scale**, independently of normalized single-precision
image values. Correlation `threshold` is a separate cutoff, not an intensity value.

For the ordinary automatic mode, use `'monitorChange',false,'adaptiveBackground',true`.
For manual masking, use `'monitorChange',false,'adaptiveBackground',false,'backgroundIntensity',30`.
The background mask is applied when `boundary=true`
(default); `boundary=false` bypasses local intensity rejection in every mode.

### srFRC monitored outputs and sjet comparison

When `monitorChange=true`, exactly three groups are retained: `bg0.8`, `bg1.0`
and `bg1.2`. The monitored run analyzes **only the first frame/pair**, even if
`batchProcessing=true` was requested.
The console prints the effective background mode, group names and group count.
Do not confuse a single result container or a single frame with one background group.

`result.maps` uses `(Y,X,T,B)` axes. **The background axis is dimension 4**;
single-frame input has `size(result.maps,3)==1` and `size(result.maps,4)==3`.
The previous compact storage already used this layout. Taking only
`result.maps(:,:,1)` selects one background map, not all backgrounds.

```matlab
result = srFRC(image,'pixelSize',pixelSize,'monitorChange',true);
result.backgroundCount                 % 3
result.backgroundRatios                % [0.8 1.0 1.2]
maps08 = result.maps(:,:,:,1);
maps10 = result.maps(:,:,:,2);
maps12 = result.maps(:,:,:,3);
```

`result.backgroundGroups` provides three named descriptors with `mapIndex`,
per-frame summaries and actual background thresholds. These descriptors do not
duplicate the full map data. `result.backgroundMode` identifies monitor,
automatic or manual mode. The compatibility sPANEL/dPANEL outputs also retain
all monitored PANEL groups: PANEL axes are `(Y,X,RGB,T,B)`, while a single-frame
legacy FRCMap retains its existing `(Y,X,B)` layout.

In the demo, set the **demo variable** `monitorChange=true`. The demo passes its
value explicitly; changing only a default inside srFRC.m does not override that
argument. Running the entire demo also clears earlier command-line variables.
The demo prints the effective mode and group count.

Plotting shows only the first frame/pair, with all three background settings
**side by side in one comparison window**. Every axes and individual PNG uses
the original `sjet` palette and a common `[0, maximum]` colour range. This affects
display only; map samples and pre-upsampling statistics are unchanged. The palette
is available through `src/Utils/sjet.m` and writes no unsolicited sJet.lut file.

The demo keeps the combined MAT/CSV summary and additionally saves each background
group as its own float32 TIFF and compact CSV:

| Group | Numerical map | Per-group summary |
| --- | --- | --- |
| bg0.8 | srFRC_bg0.8_resolution-map.tif | srFRC_bg0.8_results.csv |
| bg1.0 | srFRC_bg1.0_resolution-map.tif | srFRC_bg1.0_results.csv |
| bg1.2 | srFRC_bg1.2_resolution-map.tif | srFRC_bg1.2_results.csv |

Each TIFF and CSV retains every computed frame/pair. Optional PNG previews use
the first-frame label and the background group name, producing three distinct
files. The numerical entry point still neither plots nor writes files.
MATLAB regression cases are in `tests/test_srfrc_monitoring.m`; run with
`runtests('tests/test_srfrc_monitoring.m')` from this repository's root.

## srFRC map restoration

Single-frame srFRC restores the reduced map to the original XY size with a
**separable cubic spline**, using MATLAB `interp1(...,'spline')` along X and
then Y, with not-a-knot boundary conditions. Fourier map restoration and the
`mapInterpolation` selection parameter have been removed. Backend metadata
records `cubic_spline`; paired maps are already full size and record `none`.

Zero-based output index j samples source coordinate j/2. Coordinates beyond the
last source sample use that edge value, including odd original dimensions.
Singleton axes are constant; axes with two or three samples use the corresponding
linear or quadratic interpolation. Existing source samples are retained at even
output coordinates. This is an interpolating cubic spline, not bicubic convolution.

The original finite positive foreground mask is repeated to the output grid;
it is never inferred from interpolated values. Points outside this support remain
zero. Non-positive candidates become zero; finite positive candidates are bounded
by the positive source minimum and maximum after source-map cleanup below.
These guards prevent interpolation artifacts from becoming extra foreground.
New spline samples can change the foreground mean; exact distribution or mean
preservation is not guaranteed or imposed.

**All resolution statistics are calculated BEFORE upsampling.** The native
rolling map is first cleaned: non-positive samples become background zero and
finite positive samples are at least **2.3 times the original pixel size in nm**.
Mean/min/max resolution and `rFRC_value=mean/min-1` are then calculated from its
finite positive foreground. Background zeros are excluded; an empty foreground
gives `NaN` statistics. Only afterwards is the map enlarged for display/export.
The spline is bounded by the cleaned source range, so restored positive values
also retain the required lower bound. The doubled diagonal-pair spacing is used
for correlation frequencies, not for a second map floor.

`result.statisticsStage` records `pre_upsampling`, and `statisticsMapSize`
records the native grid dimensions. `result.summary` and exported summary rows
use the same pre-upsampling values. `result.maps` and exported TIFF/PNG maps
retain the original image size; their spatial mean can differ from the summary.

Numerical and demo helpers are located in `src/Utils/`, with the shared
FRC/FSC numerical helper functions in `src/fSNR/`. Compatibility entry points
`sPANEL.m` and `dPANEL.m` remain in `src/Utils/`; they are not separate public
plotting modules.

## Demo outputs

The demos read example TIFF files under project-root `example_data/`.
With saving enabled, the demo creates **`fullfile(pwd,'results')`** and invokes
the utilities. Plot/export implementations are in `src/Utils/`; file handling
is not added to the numerical functions.

| Utility | Role |
| --- | --- |
| `save_demo_summary.m` | Compact CSV and MAT export; sFSC interpretation text |
| `plot_correlation_curve.m`, `plot_sfrc_results.m` | sFRC curve display and optional PNG previews |
| `plot_sfsc_results.m` | Resolution/DRI figures and optional PNG previews |
| `plot_srfrc_results.m` | First-frame sjet comparison and one PNG per background group |
| `save_srfrc_maps.m` | Final numeric-map TIFF export |
| `imwritestack.m` | Shared float32 TIFF writer; optional image description |

Plot helpers accept an empty directory to display without exporting. Saving
numerical data does not require plotting. `src/Utils/imwritestack.m` is the shared float32 TIFF writer;
`save_srfrc_maps.m` uses it to preserve numerical map values. The writer performs
no normalization; map exports include nm units and page order in the description.
The `demos/` folder contains `sFRC_demo.m`, `sFSC_demo.m` and `srFRC_demo.m`;
the relevant helpers are in `src/Utils/`.

| Content | Filename examples |
| --- | --- |
| Compact summary | `sFRC_results.csv`, `sFSC_results.csv`, `srFRC_results.csv` |
| Numerical results / parameters | `sFRC_results.mat`, `sFSC_results.mat`, `srFRC_results.mat` |
| E_DRI interpretation | `sFSC_E-DRI-guidance.txt` |
| Optional previews | `sFRC_frame0001_correlation-curve.png`, `sFSC_lateral-axial-resolution.png`, `sFSC_DRI-elliptical-fit.png` |
| Final numeric maps | `srFRC_bg1.2_resolution-map.tif`, `srFRC_manual-bg_resolution-map.tif` |
| Per-frame map preview | `srFRC_frame0001_bg1.2_resolution-map.png` |

Frame identifiers use `frame0001`; pairs use `pair0001-0002`. srFRC maps have
axes `YXTB`; each background setting is exported as one multipage YXT TIFF.
The `bg1.2` label is an Otsu multiplier; the actual intensity threshold is
stored in `background_threshold` and `backgroundThresholds`. Manual background
uses `manual-bg`. TIFF, MAT and summaries use the same final restored maps.
Repeated runs overwrite matching filenames and leave other result files intact.
