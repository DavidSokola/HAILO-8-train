Below is a summary of the key parameters and architectural details extracted from the ONNX graph. These details are critical when preparing the network for Hailo DFC calibration, fine‐tuning, and ultimately for HEF (Hailo Executable Format) generation.

1. Input & Data Types
Input Tensor:
Name: images
Shape: 1 × 3 × 640 × 640
Data Type: FLOAT
Weights/Biases:
All weights and biases are stored as FLOAT.
Constants:
Several constants appear (both FLOAT and INT64) for operations like reshape and split.
2. Overall Network Structure
Architecture Overview:
The network is composed of multiple convolutional blocks (labeled as model.0 through model.24), many of which are grouped into submodules (e.g. m.0, m.1, etc.). The design exhibits:
Gated Convolutional Blocks: Many layers follow a pattern where the convolution output is multiplied element‐wise with its Sigmoid activation (i.e. Conv → Sigmoid → Mul).
Skip/Residual Connections: Several blocks use addition and concatenation to fuse features from different paths.
Multi-Scale Feature Fusion: Later stages combine outputs via concatenations (often along channel axis) and involve operations such as upsampling (using Resize) and pooling.
3. Convolutional Layers & Key Parameters
Layer 0 (Initial Block):

Operation: Convolution
Kernel Shape: 6 × 6
Filters: 16
Strides: [2, 2]
Pads: [2, 2, 2, 2]
Followed By: Sigmoid activation and element‐wise multiplication (gating mechanism).
Layer 1:

Operation: Convolution
Kernel Shape: 3 × 3
Filters: 32
Strides: [2, 2]
Pads: [1, 1, 1, 1]
Intermediate Blocks (e.g. model.2, model.4, model.6, model.8, model.17):

Kernel Shapes: A mix of 1×1 (for channel reduction/expansion) and 3×3 (for spatial feature extraction).
Gated Units & Residual Branches: They include parallel conv branches whose outputs are combined via addition or concatenation.
Notable Filter Counts:
For instance, later blocks show increasing channel dimensions (e.g. 64, 128, 256) to capture more abstract features.
Downsampling:

Many conv layers use stride 2 (or MaxPool with a 5×5 kernel and stride 1) to reduce spatial dimensions gradually.
Detection Head (Final Stages):

The final block (model.24) splits into several branches.
Convolution Weights: Shapes like [27, 64, 1, 1], [27, 128, 1, 1], and [27, 256, 1, 1] suggest that each branch is outputting 27 channels.
Interpretation: In many detection architectures (e.g. YOLO-like), the “27” channels could correspond to 3 anchors × (4 bounding box coordinates + 1 objectness + 21 class scores) or a similar scheme.
Output Fusion: Three different outputs (after various reshape, transpose, and split operations) are concatenated to form the final output tensor.
4. Activation, Pooling, and Other Operations
Activation Function:

Sigmoid: Used extensively after each convolution before the element‐wise multiplication. This “gated” mechanism is consistent throughout the network.
Pooling & Upsampling:

MaxPool: Found in model.9 – using a 5×5 kernel with appropriate padding (likely to capture context at one scale).
Resize (Upsampling): Used in layers like model.11 and model.15 with the “nearest” mode (and parameters such as cubic_coeff_a = -0.75), likely for merging multi-scale features.
Concatenation & Splits:

Concat: Frequently applied along the channel axis to fuse features from different branches.
Split & Reshape: The final layers use split operations (along axis 4) and reshapes to organize the outputs into the expected detection format.
5. Implications for Hailo DFC Calibration & HEF Conversion
Calibration & Fine Tuning:

Dynamic Ranges: Knowing that all operations are FLOAT and the gating mechanism (conv output × sigmoid) is used, it is important to capture the dynamic range of activations during calibration.
Layer Parameters: The detailed kernel sizes, strides, and padding values are essential to correctly map the network operations onto the Hailo hardware.
Multi-Scale Fusion: The presence of multiple scales (via pooling, resize, and concatenation) must be handled properly during quantization and calibration.
HEF Output Considerations:

Graph Structure Preservation: The final HEF file must preserve the detailed operator graph (including splits, reshapes, and transpositions) so that the detection heads output correctly.
Anchor/Detection Configuration: The three detection branches with 27 output channels each are a key parameter. They must be calibrated and possibly fine-tuned to ensure proper inference performance on Hailo devices.
Operator Support: All used operations (convolutions, element-wise multiplications, Sigmoid, Resize, etc.) need to be supported or correctly mapped in the HEF generation process.
Summary
Input: 1×3×640×640, FLOAT
Convolutional Blocks:
Early layers use 6×6 and 3×3 convolutions with strides of 2 and appropriate padding.
Intermediate layers combine 1×1 and 3×3 convolutions with gating (using Sigmoid → Mul) and include skip/residual connections.
Filter counts progressively increase (16 → 32 → 64 → 128 → 256, etc.).
Detection Head:
Final layers output tensors with 27 channels per branch, split and fused to form the overall detection output.
Additional Operations:
Multiple MaxPool, Resize, Concat, and Split operators are used for multi-scale feature fusion.
For Hailo Calibration & HEF:
All these parameters (input dimensions, convolution kernel/stride/pad, activation functions, multi-scale design, and output tensor configuration) are essential for proper calibration, fine-tuning, and mapping to the HEF file.
