# Advanced parameters and result interpretation — MATLAB

Return to the [README](../README.md).

This guide applies to this MATLAB repository. The numerical entry points are
`sFRC`, `sFSC`, and `srFRC` in `src/`. They accept image arrays and return
numerical results. The demos read the example TIFF files and decide whether
to invoke plotting and export utilities from `utils/`.

## Threshold choices and demo auto plotting

All three functions accept the two correlation criteria `1/7 hard threshold` and
`3-sigma`. The fixed criterion is the default for sFRC/sFSC; **srFRC retains
`threshold='3-sigma'` by default**. The existing spelling `'1/7'` is an alias;
`'fixed_threshold'` is accepted as another fixed-criterion alias for script
compatibility. Internal curves and summary parameters retain the key `'1/7'`.
These aliases are not extra criteria. 2-sigma/5-sigma are not public choices.

Example: `srFRC(image,'threshold','1/7 hard threshold')` selects 1/7 as the
primary criterion. Serial and parallel calculations preserve the internal
fallback order: **primary, then 5-sigma x 0.6, then 2-sigma x 1.5**. A window
becomes zero only when no criterion provides a finite positive estimate. The
summary identifies the selected primary criterion. Sigma padding calibration
is retained and the hard cutoff stays exactly 1/7. Local curves are not extrapolated.

Plotting stays in the demos and `utils/`; **no plot argument is added to any
numerical function**. The sFRC/srFRC demos use `plotMode='auto'` and resolve it with
`resolve_demo_plot`:

| Demo settings | Display behavior |
| --- | --- |
| batchProcessing=true (default) | Compute all frames/pairs; preview only currentFrame |
| batchProcessing=false, singleFrame=true | Show only the one-based currentFrame result |
| batchProcessing=false, singleFrame=false | Show the calculation for currentFrame and the following frame |
| plotMode=false | Always hide plots |

`plotMode=true` requests the same single current-frame display as auto,
independently of batching. The helper also accepts text 'true'/'false'. sFSC treats its stack as
one 3D volume and always displays an available result in the demo. Its demo has
no `plotMode` or `plotResults` switch; `plotFittingCurve` controls only the extra DRI-fit figure. Numerical exports contain
all computed frames; PNG previews contain only the current frame/pair, including
its background-comparison group. If a paired preview has no following frame,
a Command Window notice explains why it cannot be shown; the numerical batch
is retained. The optional save/display sections remain separate from computation
and outputs still use results/.

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
| `xyMode` | `'slice'` | Lateral estimation from slices; `'3D'` uses the central Fourier plane |
| `motionCorrection` | `false` | Align paired inputs; not used for single-frame pair generation |
| `progress` | `true` | Display sFSC progress bars |

sFRC/srFRC share `singleFrame=true`, `batchProcessing=true`,
`currentFrame=1`, and `motionCorrection=false`. Their `pixelSize` default is
`0.02` um; replace it with the calibrated spacing. sFSC has a default
`pixelSize=[0.03 0.03 0.1]` um, which also needs acquisition-specific calibration.

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

sFRC/srFRC use one `(Y,X,T)` stack. With `batchProcessing=true`, an N-frame
single-frame stack produces N results; `singleFrame=false` produces N-1
overlapping adjacent pairs: `(1,2)`, `(2,3)`, ..., `(N-1,N)`. Paired mode
requires at least two frames.

With `batchProcessing=false`, `currentFrame` selects one **one-based** frame.
Paired mode also uses the following frame. sFSC instead analyzes a 3D volume
or volume pair and has no 2D-stack batch switch.

Plotting controls belong only to the demos. The numerical functions accept
no `plot`, `plotFittingCurve`, save switch, output directory, or base-name
arguments. sFRC/srFRC demos show only currentFrame by default with batching ON or OFF.
Paired mode shows one result for currentFrame and the next frame. The sFRC/srFRC
demo controls are `plotMode`, its resolved `plotResults`, and `saveResults`.
The sFSC demo always calls `plot_sfsc_results` for the completed result, with no
master plotting switch. `plotFittingCurve=false` remains the independent default
for the additional DRI-fit figure; `saveResults` still controls file writing.

## srFRC background parameter relationships

`monitorChange=true` takes priority and **forces `adaptiveBackground=false`**
before calculation. It still runs its own Otsu comparison; it does not select
manual-background mode.

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
and `bg1.2`. This remains true when adaptiveBackground is requested as false,
for a single image, for a selected frame and for complete-stack batching.
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
The demo now prints the resulting effective mode and group count.

Plotting shows only the current frame/pair, with all three background settings
**side by side in one comparison window**. Every axes and individual PNG uses
the original `sjet` palette and a common `[0, maximum]` colour range. This affects
display only; map samples and pre-upsampling statistics are unchanged. The palette
is available through utils/sjet.m and writes no unsolicited sJet.lut file.

The demo keeps the combined MAT/CSV summary and additionally saves each background
group as its own float32 TIFF and compact CSV:

| Group | Numerical map | Per-group summary |
| --- | --- | --- |
| bg0.8 | srFRC_bg0.8_resolution-map.tif | srFRC_bg0.8_results.csv |
| bg1.0 | srFRC_bg1.0_resolution-map.tif | srFRC_bg1.0_results.csv |
| bg1.2 | srFRC_bg1.2_resolution-map.tif | srFRC_bg1.2_results.csv |

Each TIFF and CSV retains every computed frame/pair. Optional PNG previews use
the current-frame label and the background group name, producing three distinct
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

All numerical srFRC project dependencies remain in
`src/srFRC_support/+srfrc_support/`. The demo uses root `utils/` only for
optional plotting/export, and the support namespace for reading its TIFF.

The legacy `dPANEL` and `sPANEL` entry points are in `src/srFRC_support/`.
Add that directory to the MATLAB path when calling them directly. `sPANEL`
temporarily resolves `srFRC` from the parent `src/` directory and uses
`srfrc_support.read_params`; the caller's path is restored on exit. Neither
compatibility entry point requires the root `utils/` directory.

## Demo outputs

The demos directly read explicit paths under project-root `example_data/`.
With saving enabled, the demo creates **`fullfile(pwd,'results')`** and invokes
the utilities. Plot/export implementations are in `utils/`; file handling
is not added to the numerical functions.

| Utility | Role |
| --- | --- |
| `save_demo_summary.m` | Compact CSV and MAT export; sFSC interpretation text |
| `plot_correlation_curve.m`, `plot_sfrc_results.m` | sFRC curve display and optional PNG previews |
| `plot_sfsc_results.m` | Resolution/DRI figures and optional PNG previews |
| `plot_srfrc_results.m` | Current-frame sjet comparison and one PNG per background group |
| `save_srfrc_maps.m` | Final numeric-map TIFF export |
| `imwritestack.m` | Shared float32 TIFF writer; optional image description |

Plot helpers accept an empty directory to display without exporting. Saving
numerical data does not require plotting. `utils/write_float_tiff.m` is a thin
compatibility entry point that delegates to the shared `imwritestack` float32
writer. `save_srfrc_maps.m` uses that same writer directly. The writer performs
no normalization; map exports include nm units and page order in the description.
The `demos/` folder contains only `sFRC_demo.m`, `sFSC_demo.m` and `srFRC_demo.m`;
all helpers are in `utils/`.

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
