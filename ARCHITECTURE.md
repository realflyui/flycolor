# FlyColor Architecture

This workflow is inspired by Radix UI's color system approach, adapted for Flutter with OKLCH color space and perceptual uniformity.

## Preparation: Conversion to OKLCH

The process initializes by converting all input colors (the $\text{accent}$, $\text{gray}$, and $\text{background}$ colors) from their sRGB hex strings into the **OKLCH** color space.

* **The Problem: Inaccurate Perception**
    Standard color spaces like sRGB are not *perceptually uniform*. This means equal steps in an RGB value do not correspond to equal steps in perceived brightness or saturation.
* **The Solution: Perceptual Uniformity**
    OKLCH separates color into three coordinates that align closely with human vision: $L$ (Lightness), $C$ (Chroma/saturation), and $H$ (Hue). This provides **precise control** to manipulate the lightness progression without corrupting the color's hue or saturation.

## Scale Selection and Blending

The goal is to create a high-quality lightness curve progression that a simple algorithm can't easily reproduce.

* **The Problem: Generating the Perfect Curve**
    Relying only on a simple mathematical formula to generate 12 steps often results in a visually dull or uneven lightness curve.
* **The Solution: Interpolation with Templates**
    The code finds the **two closest predefined template scales** (inspired by Radix UI's color system) by iterating through all colors in the template library and measuring the difference using the **$\Delta E_{OK}$** (delta E OKLCH) color difference metric. It then selects the two closest scales (ensuring they're unique) and handles special cases like removing duplicate gray scales.

    It then uses **trigonometry** (law of cosines with cosine and tangent ratios) to determine the precise proportional blending $\text{ratio}$ between these two templates (A and B). The ratio is calculated using the law of cosines and then multiplied by a mixing factor (0.5). This creates a bespoke 12-step scale that lies exactly along the color trajectory of the user's input, combining the visual quality of the hand-tuned templates.

## Chroma and Hue Correction

After blending, the template has a great progression, but its color identity (hue and saturation) is just an average.

* **The Problem: Color Drift**
    The blending process averages the $\text{Hue}$ ($H$) and $\text{Chroma}$ ($C$) of the two reference scales. The resulting scale is an approximation and might be slightly $\text{off-hue}$ or have the wrong overall saturation compared to the user's input.
* **The Solution: Force the Color Identity**
    The code explicitly overrides the $\text{Hue}$ and scales the $\text{Chroma}$ of the blended template to match the user's seed color.
    1.  The $\text{Hue}$ ($H$) of the seed color is assigned directly to all 12 steps.
    2.  The code finds the closest color in the blended scale to the seed color, then calculates a chroma ratio. The $\text{Chroma}$ ($C$) of every step is scaled by this ratio, with a cap to prevent oversaturation.

    This ensures the scale has the optimal progression but the unmistakable $\text{Hue}$ and appropriate saturation of the original input:

    $$C_{i}^{\text{final}} = \min\left(C_{\text{seed}} \times 1.5, C_{i}^{\text{blended}} \times \left( \frac{C_{\text{seed}}}{C_{\text{base}}} \right)\right)$$

## Lightness Curve Transposition

The generated scale must maintain its functional contrast when placed on any background color, not just a default one.

* **The Problem: Fixed Contrast**
    The low-contrast steps ($L_1$, $L_2$) are highly sensitive to background changes. If the $\text{background}$ is much lighter or darker, these steps can lose their intended subtle difference.
* **The Solution: Guarantee Relative Contrast**
    The algorithm **transposes** the entire lightness ($L$) curve to anchor it to the user's $\text{background}$. The implementation differs for light and dark modes:

    **Light Mode**: The algorithm prepends a value of 1.0 to the lightness array before transposing, ensuring the lightest step anchors properly. It calculates the lightness $\text{diff}$ between the background and the first step's lightness:
    $$\text{diff} = L_{\text{step1}} - L_{\text{background}}$$
    This $\text{diff}$ is then applied across the entire scale using the `_transposeProgressionStart` function with a **Bezier easing function** $\text{[0, 2, 0, 2]}$ to non-linearly distribute the shift.

    **Dark Mode**: The algorithm adjusts the easing curve dynamically based on the ratio between the background lightness and the reference background lightness. If the ratio exceeds 1.0, it scales down the easing values to prevent over-adjustment.

    The transposition formula (simplified):
    $$L_{i,\text{final}} = L_{i,\text{template}} - \text{diff} \times \text{BezierEase}(1 - i / \text{lastIndex})$$

## Final Output and Alpha Calculation

The final step generates transparent scale formats for both accent and gray scales.

* **The Problem: Inconsistent Transparency**
    Standard CSS opacity is relative and visually unpredictable. The transparent steps ($\text{a1-a12}$) must always look correct *as if* they were the regular steps faded onto the user's specific $\text{background}$.
* **The Solution: Pre-Blended Alpha Colors**
    The code uses the `_getAlphaColorSrgb` function to perform **reverse alpha blending**. The implementation is more sophisticated than a simple algebraic solution:

    1. It calculates per-channel alpha values (R, G, B) separately
    2. For pure gray colors (where all channel alphas are equal), it uses a simplified calculation
    3. For colored targets, it uses the maximum alpha across all channels and adjusts the foreground color to ensure exact matching
    4. It includes fine-tuning adjustments to account for rounding errors in the blending calculation

    The underlying blending equation is:
    $$\text{Target} = \text{Background} \times (1 - \alpha) + \text{Foreground} \times \alpha$$

    The output is a single hex string with an alpha channel (e.g., `#RRGGBBAA`), which locks the visual blend for absolute consistency across the UI. The function also generates a surface color variant with a specific alpha value (0.8 for light mode, 0.5 for dark mode).

---

## Post-Processing Steps

After the core 5-step generation process, several additional refinements are applied:

1. **Step 9 Color Adjustment**: The algorithm determines whether to use the original accent color or the generated scale's step 9 based on the perceptual distance between the accent and background. If the distance is less than 25 (in ΔE_OK × 100), it uses the scale's step 9 to ensure sufficient contrast.

2. **Step 9 Button Hover**: A specialized hover color is generated for step 9 by adjusting lightness and chroma, then finding the closest matching color from the scale to maintain visual consistency.

3. **Steps 10-11 Chroma Capping**: The chroma values for steps 10 and 11 are capped to not exceed the maximum chroma of steps 7-8, preventing oversaturation in the darkest steps.

4. **Contrast Color Calculation**: A contrast color is calculated using APCA (Advanced Perceptual Contrast Algorithm) to ensure readable text on accent backgrounds. If the contrast is insufficient (< 40), it generates a custom dark color with appropriate chroma.

5. **Pure White/Black Handling**: If the accent color is pure white or black, the accent scale is replaced with the gray scale to maintain usability.
