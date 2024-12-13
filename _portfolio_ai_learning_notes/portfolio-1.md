---
title: "[NN Basics Part 1] Manual Back Propagation"
excerpt: "Refreshing basic concepts of back propagation, chain rule, derivates, gradients, etc...<br/><img src='https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_backprop_manual_derivate_result.png' width= 800 height= 800> "
collection: portfolio
---

# Overview

This is an space that I've created to teach my self and refresh some concepts that are very important in Neuronal Networks. One very important is back propagation.

Back prograpation is this algorithm that allows to efficiently evaluated the gradient of some kind of loss function, with respect to the weights of the neuronal network, and we can iteratively tune the weights of the neuronal network to minimize this "Loss function" and therefore improve the accuracy of the neuronal network. 

## What is this toy project about?

The main idea is to create a class with properties similar to PyTorch: forward and backpropagation, ReLU functions, basic arithmetic operations like addition and division, and more. By doing this, I'll gain a better understanding of how the PyTorch library works behind the scenes.

Even though I'll go through some basic functionalities of the PyTorch library, the primary goal is to understand backpropagation and chain rule. I want to illustrate how backpropagation and derivatives are merely tools used by neural networks, and show that these processes ultimately boil down to mathematical operations performed on matrices.

On top of this library a basic neuronal network will be build from scratch too.

# Start

## Loss function 

A loss function in a neural network is basically a way to measure how "wrong" the network’s predictions are compared to the actual answers we want. Think of it like a score that tells the network how bad it did on a given guess. The goal is to make that "wrongness score" as low as possible, so the network adjusts its internal settings (weights and biases) to improve next time.

Example:
Imagine you have a neural network trying to tell whether a picture is of a cat or a dog. If the network looks at a cat picture and confidently says "dog," the loss function gives a high score, meaning "That was a pretty bad guess." If the network sees a dog and says "I think it’s 95% likely to be a dog," the loss will be very low, because it was close to the right answer. Over time, the network uses these loss values to learn and get better at telling cats and dogs apart.

## Math

### Derivates
It is important to have a general idea of what derivates do in a NN, and the knowledge adquired in calculus class will help a lot. In NN we won't apply huge math expresion to calculate the derivate of a number with respect to another, what we do is to apply the chain rule. But to go there first is better to understar the basic concepts of derivates.

If I have a function, for example a cuadratic function, where F(x) = 3x**2 - 7x + 10, I would get a curve in a graph. and if I apply the derivates formula $$ L = \lim_{h \to 0} \frac{f(a+h) - f(a)}{h} $$ what I'm doing is add an small number in the X axis and substract the original X value to get the "Slope"

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_example_slope.png">

An small exercise to apply derivates in python using basic mathematical operation, it is like this:

    ```python
    # Set a small increment value for numerical differentiation
    h = 0.0001

    # Define three constants to be used in the evaluation formula
    a = 2.0
    b = -3.0 
    c = 10.0

    # Calculate the initial result of the formula a*b + c
    d1 = a*b + c

    # Increment c by h and recalculate the result to observe the change
    c += h  # <-------
    d2 = a*b + c

    # Print the results of the calculations
    print(f"{d1=}")
    print(f"{d2=}")
    print(f"Slope = {(d2 - d1) / h}")
    
    #Result
    d1=4.0
    d2=4.0001
    Slope = 0.9999999999976694


This example demonstrates how the derivative of d2 with respect to d1 is calculated when the value of c is incremented by h.

### Graph to show derivates with respect to the "Loss Function"

While learning about derivatives in neural networks, the following example helped me to understand much better.

I had to developed a specialized data structure called "Value" that includes methods for basic mathematical operations such as addition and multiplication. This class contains several attributes: "_prev" to store its child nodes, "_op" to indicate the mathematical operation used to create this value, "grad" represent the derivated of the "Loss function" or "L"  with respect to the current variable, and "label" to store the name of the current variable.

The goal is to visually illustrate how a constant or variable affects the "Loss function" through its derivative. These values will act as simulated weights in a neural network.

Utilize a predefined function to generate a graph representing these mathematical operations.  

### Class Value

    ```python
      class value():
      def __init__(self, data, _children = (), _op = None, label = ''):
          self.data = data
          self._prev = set(_children)
          self._op = _op
          self.grad = 0
          self.label = label

      def __repr__(self):
          return  f" Value(data={self.data})"

      def tanh(self):
          n = self.data
          tanh = (math.exp(2*n) - 1) / (math.exp(2*n) +1)
          out = value(tanh, (self, ) , 'tanh')
          return out
      
      def __add__(self,other):
          if isinstance(other,value):
              out = value(self.data + other.data, (self,other), '+')
              self.grad = out.grad

              return out
      
      def __mul__(self,other):
          if isinstance(other,value):
              return value(self.data * other.data, (self,other), '*')

      a = value(3, label = 'a')
      b = value(5, label = 'b')
      c = a + b; c.label= 'c'
      d = a * b + c; d.label = 'd'

### Graph function

    ```python
    import graphviz  
    from IPython.display import display, SVG

    def get_nodes_edges(root):
        # build a set upt with all the nodes and edges
        nodes, edges = set(), set()
        def build(v):
            if v not in nodes:
                nodes.add(v)
                for child in v._prev:
                    edges.add((child, v))
                    build(child)
        build(root)
        return nodes, edges

    def draw_graph(root):
        ps = graphviz.Digraph(format = 'svg', graph_attr = {'rankdir' : 'LR'} )
        nodes, edges = get_nodes_edges(root)

        for n in nodes:
          uid = str(id(n))
          #for any value in the graph, create a rectangle with the data of the value 
          {% raw %}
          ps.node(uid, label = "{%s | data %.3f | grad %.3f}" % (n.label, n.data, n.grad), shape = 'record')
          {% endraw %}
          
          if n._op:
              #if this value is a result of an operation, create a circle with the operation
              ps.node(name =uid + n._op, label = n._op)
              #create an edge between the value and the operation
              ps.edge(uid + n._op, uid)

        for n1, n2 in edges:
            #connect the nodes
            ps.edge(str(id(n1)), str(id(n2)) + n2._op )

        svg_data = ps.pipe(format='svg')
        display(SVG(svg_data))

The new function {draw_graph} receives a variable called **root** to be graphed with all the values necessary to calculate it. If you call "draw_graph(d)," you could get something like this.


<img src = 'https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_graph_nodes.png'>

What I've done so far is use a graph function to visualize mathematical expressions, this mathematical way to see the graph represent the forward pass in a neuronal network, where for example "d", the final value, would represent the Loss function, and the values behind are the weights. **What we like to do next is apply back propagation**.

### Example 

For this example, I worked with an structure very similar to a Neuron, where it receives inputs values and multiply it by weights to generate an output. I also applied an activation function, in this case a tanh. I want to talk mor about activation functions later, bbecause it is a very interesting topic, and I don't want to loss the point also.

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/porfolio_ia_neuron_example.png" width = 400 height = 400>

the script to inicializate the values is: 

    #Inputs x1, x2
    x1 = value(2.0, label = "x1")
    x2 = value(0.0, label = "x2")
    # weights w1, w2
    w1 = value(-3.0, label = "w1")
    w2 = value(1.0, label = "w2")
    #bias of the neuron
    b = value(6.7, label = 'b')
    #x1*w1 + x2*b2 
    x1w1 = x1*w1; x1w1.label = "x1w1"    
    x2w2 = x2*w2; x2w2.label = "x2w2"
    # add bias
    x1w1x2w2 = x1w1+x2w2; x1w1x2w2.label = "x1w1x2w2"
    n = x1w1x2w2 + b;  n.label = "n"
    o = n.tanh(); o.label = "o"

    draw_graph(o)

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/porfolio_ai_neuron_nodes_example.png" width = 1200 height = 2000>

The mathematical operation values are saved in "data," which will allow us to apply backpropagation by differentiating each node with respect to **o**. Two important things to mention at this points are:

  - The chain rule is an important principle that allows us to measure how a variable or weight deep within the neural network affects the output. Essentially, the chain rule tells us that to determine this, we should measure both the local derivative and the global derivative. What does this mean? For example, if we're deep in the neural network, as shown in the figure above, and we focus on the node w1 * x1 = x1w1, if I already know the derivative of x1w1 with respect to **o**, it would be the global derivative. I would then just need to calculate the local derivative, which is the derivative of w1 with respect to x1w1, and multiply them. In that way I could calculate the derivate of w1 with respecto to the **o**, that is a value far away from it.
  - Our main goal in this small example, or what we really care about, is to find the derivatives of w1 and w2 with respect to **o**. This is because they are the weights at the beginning of the graph that we will need to change (tune) to adjust the output as desired.


### Derivating the graph with chain rule

- First is first, derivated of **o** with respecto to **o**, do/do = 1.

- Second the derivated of **n** with respect to **o**, do/dn

$$
\frac{d}{dx} \tanh x = 1 - \tanh^2 = 1 - 0.604 ^2 = 0.64
$$

- Now, the next step in backpropagation is straightforward due to the **+** operation, which simply distributes the gradient through the node. This means that the local derivative is always **1** when a **+** operation is involved. For example, in this case:

      dn/db #Derivative of b with respect to n, indicating how much n is affected by a small change in b
      n = x1w1x2w2 + b  # The base formula for n 

      // Applying the basic rule of derivatives: (f(x+h) - f(x)) / h
      (f(x+h) - f(x)) / h 
      // Substitute f(x) with x1w1x2w2 + b and f(x+h) with x1w1x2w2 + (b + h)
      (x1w1x2w2 + (b + h)) - (x1w1x2w2 + b) / h 
      // Expand the expression: x1w1x2w2 + b + h - x1w1x2w2 - b
      x1w1x2w2 + b + h - x1w1x2w2 - b / h 
      // Simplify the expression: h / h
      h / h 
      // Final result: 1, which is the derivative of n with respect to b
      1 

- Following the same rule, we could define that 0.64 grad would flow until the nodes x1w1 and x2w2.

- To define do/x2, do/w2, do/x1 and do/w1 I could apply the chain rule.


      do/x2 = do/x2w2 * x2w2/x2  # Global derivated * Local derivate
      do/x2w2 = 0.64 #Global derivated
      dx2w2/x2 = w2 #Local derivate

      #Showing dx2w2/x2
      // Applying the basic rule of derivatives: (f(x + h) - f(x)) / h
      (f(x + h) - f(x) / h)
      // Substitute f(x) with x2 * w2 and f(x + h) with (x2 + h) * w2
      ((x2 + h) * w2) - (x2 * w2) / h
      // Expand the expression: x2w2 + hw2 - x2w2
      x2w2 + hw2 - x2w2 / h
      // Simplify the expression: hw2 / h
      hw2 / h
      // Final result: w2, which is the derivative of x2w2 with respect to x2
      w2

      do/x2 = do/x2w2 * x2w2/x2  # Global derivated * Local derivate
      0.64 * w2 # Final result derivate


In this context, the gradient of a variable involved in a multiplication is determined by the value of the other variable in the multiplication. This means that when calculating the gradient, the contribution of one variable is directly influenced by the magnitude of the other variables. 

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_backprop_derivate_example.png" width = 400 height= 400>  

Now if I update the gradients for the variables, the graph would look like this:  

    o.grad = 1
    n.grad = 0.64
    b.grad = 0.64
    x1w1x2w2.grad = 0.64
    x2w2.grad = 0.64
    x1w1.grad = 0.64

    w1.grad = x1.data * x1w1.grad
    x1.grad = w1.data * x1w1.grad

    w2.grad = x2.data * x2w2.grad
    x2.grad = w2.data * x2w2.grad

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_backprop_manual_derivate_result.png">  

In this way I've just calculated the gradients with respect to **o** manually. It is something quite usefull to understand how back propagation works in a Neuronal network. 

I would like to leave this topic until here, it is because what comes next is automatice this back propagation process with python, show how similar is with pytorh and create a neuronal network from scratch base on it. My main idea was here save knowledge about back propagation, to talk about neuronal networks in python I will use this space [link](/portfolio_ai_learning_notes/portfolio-2) ...
