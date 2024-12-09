---
title: "GPT Transformer"
excerpt: "Creation Neuronal Network with pytorch and transfomers<br/><img src='https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_1_tranformers.png'>"
collection: portfolio
---

# Overview

This project involves building and training a language model using a Transformer-based neural network architecture on the Tiny Shakespeare dataset. The Transformer, a type of deep learning model heavily used in Natural Language Processing (NLP), enables the model to "read" sequences of text and learn statistical patterns that can then be leveraged to generate new, Shakespeare-style text. Unlike older sequence models (such as RNNs or LSTMs), Transformers utilize an attention mechanism to capture long-range dependencies in text more effectively.

**Key Educational Concepts Covered:**

- **Neural Networks & Differentiation:**  
  We will touch upon what neural networks are, how forward and backward passes work, and the role of derivatives in training.
  
- **Transformer Architecture:**  
  We will explain the attention mechanism, multi-head attention, feed-forward layers, and positional embeddings.
  
- **Training Dynamics:**  
  Discuss how the model processes inputs, calculates a loss function, and updates its parameters via backpropagation.

- **Implementation Details:**  
  We’ll review the PyTorch code structure and highlight the key building blocks of a Transformer-based language model.

**Illustration of the Transformer Forward Pass:**


    Input text indices --> [Embedding Layer] --> [Positional Embedding] --> [Transformer Blocks]
        (tokens)                                            |
                                                            v
                                            [Multi-Head Attention] --> [Feed-Forward Layer]
                                                            |
                                                            v
                                                [Layer Normalization]
                                                            |
                                                            v
                                                    [Final Linear Head]
                                                            |
                                                            v
                                                    Output Logits
