---
title: "[NN Basics Part 2] Automatic Back Propagation and Neuronal network"
excerpt: "Continuation of back propagation, automatic back propagation, basic neuronal networ from scratch.<br/><img src='https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_nn_image.png' width= 300 height= 300> "
collection: portfolio
---

# Overview

This text continues the topic of backpropagation from the last post. The main idea here is to add new functionalities to the class 'value' that will allow me to use other mathematical expressions like division, subtraction, exponentiation, and others, and of course, functionalities to backpropagate through them in the graph shown in "Manual Back Propagation" [link](https://jvilchesf.github.io/portfolio.github.io/portfolio_ai_learning_notes/portfolio-1/).

Additionally, I will use the "value" class to create a basic neural network with some hidden layers to optimize a loss function as an example.

# Automatic Back Porpagation

To execute automatic backpropagation, it is necessary to add a backpropagation function to each mathematical operation of the `value` class. What this function will do is propagate the gradients when this small operation is executed, transforming the output gradient (global gradient coming from a previous calculation) into an internal gradient (local gradient).

For example, an easy one to explain is addition. Each time I perform an addition as part of the neural network math process, I can calculate the gradient for the current operation based on the chain rule: `global derivative * local derivative`.

When I execute 2 + 2, what is really happening is `2.__add__(2)`. Then, what is received by the `__add__` function below is self (2) and other (2). First, out is defined as the primary goal of this function, which is to add these two numbers. Afterward, backward is the function executed. The local derivative of self.grad is 1.0 * out.grad (as seen in the manual propagation post [link](https://jvilchesf.github.io/portfolio.github.io/portfolio_ai_learning_notes/portfolio-1/), and other.grad will be out.grad, the global derivative. We will later call this function to propagate the gradient.

    def __add__(self,other):
        other = other if isinstance(other,value) else value(other)  
        out = value(self.data + other.data, (self,other), '+')

        def _backward():
            self.grad +=  out.grad  # < -------
            other.grad += out.grad # < -------
        out._backward = _backward
        return out  

Similarly, with multiplication, define _backward as a function that will propagate the gradients. For example, 2 * 2 is equivalent to `2.__mul__(2)`. The function below will receive these two variables as parameters, and the primary goal is to multiply self.data and other.data.

The secondary goal is to propagate the gradients. For this, I referred to the example shown in the "manual propagation" post, where I demonstrated how the global and local derivatives interact and multiply to determine the gradients.

    def __mul__(self,other):
        other = other if isinstance(other,value) else value(other) 
        out = value(self.data * other.data, (self,other), '*')
        def _backward():    
            self.grad += other.data * out.grad 
            other.grad += self.data * out.grad
        out._backward = _backward
        return out
        

<img src= "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_backwards_function.png">

Tanh will be the last function to add _backwards, and it will look like this.


        def tanh(self):
            n = self.data
            tanh = (math.exp(2*n) - 1) / (math.exp(2*n) +1)
            out = value(tanh, (self, ) , 'tanh')

            def _backward():
                self.grad += (1 - tanh**2) * out.grad
            out._backward = _backward
            return out


Now I should be able to execute _backward in the right order to get same results as when I was executing manually. To set up this test I will show the empthy node graph for the gradient variable and all the values involved in the text.

### Values

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

### Node Graph empty grad

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_example_automatic_backprop_graph.png">

### Exeuction and Results

        o.grad = 1.0
        o._backward()
        n._backward()
        x1w1x2w2._backward()
        b._backward()
        x2w2._backward()
        x1w1._backward()
        x2._backward()
        w2._backward()
        w1._backward()
        x1._backward()
        draw_graph(o)

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_example_automatic_backprop_graph_result.png">

### Topological sort

Going backward through this _backward expression one by one is another issue that can be easily resolved with a piece of code that applies topological sort. It is not something that caught my attention to delve into deeply, but what it basically does is return a list based on the main node and its children, processing all the child nodes and adding the main node at the end.

        topo = []
        visited = set()
        def build_topo(v):
            if v not in visited:
                visited.add(v)
                for child in v._prev:
                    build_topo(child)
                topo.append(v)
        build_topo(o)

        print(topo)

        [ Value(data=-3.0),
        Value(data=2.0),
        Value(data=-6.0),
        Value(data=1.0),
        Value(data=0.0),
        Value(data=0.0),
        Value(data=-6.0),
        Value(data=6.7),
        Value(data=0.7000000000000002),
        Value(data=0.6043677771171636)]

Now that I have the entire graph in a list, I can iterate over it with a for loop, for example, to apply the _backward function to each node and get the same results as before.

        o.grad = 1.0
        for node in reversed(topo):
            node._backward()

Now I'll paste a big piece of code with an final update for the class value, it might look Overwhelming but it is basically the same as before, it just has some new mathematicall functionalities with its _backward functions.


    ############Part 1 ###########

    class value():
        def __init__(self, data, _children = (), _op = '', label = ''):
            self.data = data
            self.grad = 0
            
            self._backward = lambda: None
            self._prev = set(_children)
            self._op = _op
            self.label = label
        
        def __add__(self,other):
            other = other if isinstance(other,value) else value(other)  
            out = value(self.data + other.data, (self,other), '+')

            def _backward():
                self.grad +=  out.grad
                other.grad += out.grad
            out._backward = _backward
            return out  

        def exp(self):
            x = self.data
            t =  np.exp(x)
            out = value(t, (self,), 'exp')
            def _backward():
                self.grad += t * out.grad
            out._backward = _backward
            return out
        
        def div(self, other):
            other = other if isinstance(other,value) else value(other)  
            out = value(self.data / other.data, (self,other), '/')
            def _backward():
                self.grad += 1 / other.data * out.grad
                other.grad += -self.data / (other.data ** 2) * out.grad
            out._backward = _backward
            return out
        

        def __mul__(self,other):
            other = other if isinstance(other,value) else value(other) 
            out = value(self.data * other.data, (self,other), '*')
            def _backward():    
                self.grad += other.data * out.grad
                other.grad += self.data * out.grad
            out._backward = _backward
            return out
        
            
        def __pow__(self,other):    
            assert isinstance(other, (int,float)), "Power must be a scalar"
            out = value(self.data ** other, (self,), f'**{other}')
            
            def _backward():
                self.grad += (other * self.data ** (other - 1)) * out.grad  
            out._backward = _backward
            return out
        
        def relu(self):
            out = value(0 if self.data < 0 else self.data, (self,), 'ReLU')

            def _backward():
                self.grad += (out.data > 0) * out.grad
            out._backward = _backward

            return out
        
        def backward(self):
            topo = []
            visited = set()
            def build_topo(v):
                if v not in visited:
                    visited.add(v)
                    for child in v._prev:
                        build_topo(child)
                    topo.append(v)
            build_topo(self)
            self.grad = 1
            for v in reversed(topo):
                v._backward()

        ############Part 2 ###########

        def __neg__(self): # -self
            return self * -1

        def __radd__(self, other): # other + self
            return self + other

        def __sub__(self, other): # self - other
            return self + (-other)

        def __rsub__(self, other): # other - self
            return other + (-self)

        def __rmul__(self, other): # other * self
            return self * other

        def __truediv__(self, other): # self / other
            return self * other**-1

        def __rtruediv__(self, other): # other / self
            return other * self**-1

        def __repr__(self):
            return f"Value(data={self.data}, grad={self.grad})"

In the first part of the code, I added several mathematical operations to provide a more detailed view of the graph, it means the graph will show more detailed operations and tanh for example won't be a one node operation anymore. Operations like `math.exp` are  in the tanh function, which relies on the math library and is not part of the `value` class, thus not appearing as a node in the graph. Similarly, operations like `division` are included. The purpose of these additions is to demonstrate that derivatives and gradients remain consistent, allowing for complete control over the mathematical operations within the graph.

Another important operation that I've seen before was added, I'm talking about topological sort, which was included in a function called `backward` at the end of the part 1.

What most of these functions do is handle cases when the mathematical expression is reversed. I talked about `a + 2 = a.__add__(2)` for example, but what happens when it is `2 + a = 2.__add__(a)`? In these cases, these functions help. Python checks if it can execute the mathematical expression, and if it can't, it looks for `__radd__`. If it finds it, the operation will be executed succesfully, if it is not founded, error.

- `__neg__(self)`: This function allows me to negate an instance of the `value` class, effectively multiplying it by -1.
- `__radd__(self, other)`: This function enables the addition of an instance of the `value` class with another value, supporting expressions like `other + self`.
- `__sub__(self, other)`: This function allows me to subtract another value from an instance of the `value` class by adding the negation of the other value.
- `__rsub__(self, other)`: This function supports the subtraction of an instance of the `value` class from another value, effectively performing `other - self`.
- `__rmul__(self, other)`: This function allows multiplication of an instance of the `value` class with another value, supporting expressions like `other * self`.
- `__truediv__(self, other)`: This function enables division of an instance of the `value` class by another value by multiplying with the reciprocal of the other value.
- `__rtruediv__(self, other)`: This function supports division of another value by an instance of the `value` class, effectively performing `other / self`.
- `__repr__(self)`: This function provides a string representation of an instance of the `value` class, displaying its data and gradient, such as `Value(data=5, grad=0.1)` for an instance with a data value of 5 and a gradient of 0.1.

Now if I update the `tanh` calculation and run the code again considering the changes that I've done one step before, I should get same results that I was gettitng manually and with more detail.

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
        #----
        e = (2*n).exp()
        o = (e-1)/(e+1); o.label = "o"
        #----
        o.backward()
        draw_graph(o)

Result code execution, maybe it is necessary to zoom in a bit. 

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_graph_open_math_expressions.png">

# Neuronal Network

Now that the value class is working, it is possible to implement a neural network class. A neural network turns out to be a specific class of mathematical expressions. I will now show how this class is built piece by piece, and in the end, I should have a "Multi-Layer Perceptron" NN.

     import random

    class Neuron:
        def __init__(self, nin):
            self.w = [value(random.uniform(-1,1)) for _ in range(len(nin))]
            self.b = random.uniform(-1,1)

        #Forward pass of this neuron
        def __call__(self, x):
            act = sum((wi * xi for wi , xi in list(zip(self.w, x))), self.b)
            out = act.tanh()
            return out

    x = [1.3, 2.1, 1.7]
    n = Neuron(x)
    n(x)
    Value(data=-0.9084999876662039, grad=0)

This `Neuron` class has two main functions: the `__init__` function, which initializes random weights and bias according to the input `X` value (nin), and the `__call__` function, which applies the forward pass step in the neural network. In this step, the `X` values are multiplied by the `weights`, the bias is added, and the `tanh` function is applied.

The next step is to define a layer of neurons, one layer of neurons. A layer of neurons is just a list of neurons, this neurons are fully connected between the current and next layer. For example, if I'm in the input layer (current layer), its neurons are fully connected with the first hidden layer (next layer).

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/porfolio_ai_nn_layers.png" width = 500 height= 500>

    import random

    class Neuron:
        def __init__(self, nin):
            self.w = [value(random.uniform(-1,1)) for _ in range(nin)]
            self.b = random.uniform(-1,1)

        #Forward pass of this neuron
        def __call__(self, x):
            act = sum((wi * xi for wi , xi in list(zip(self.w, x))), self.b)
            out = act.tanh()
            return out
            #return w_x[0] if len(x_w) == 1

    class Layer: 
        def __init__(self, nin, nout):
            """
            Layer initialization class
            
            This function will create a list of neurons based on the input arguments. These neurons will be used in the call function later.

            Args
            nin: Input dimensionallity, for example in this case it X is 3
            nout: Number of neurons that I want to create
            """
            self.neurons = [Neuron(nin) for _ in range(nout)]

        def __call__(self, x):
            """
            Function to call the neurons created in the initialization and apply forward pass

            Args
            x: Input values
            """
            out = [neuron(x) for neuron in self.neurons]
            return out

    x = [1.3, 2.1, 1.7]
    l = Layer(3, 6)
    l(x)


The new Layer class has two functions: `__init__` and `__call__`. The main goal of the `__init__` function is to create a list of neurons based on the `nout` argument received, which specifies how many neurons are needed. The `nin` parameter defines the `X` input dimensionality, which is necessary to create the weights for each neuron. This list of neurons is used by the `__call__` function, which essentially performs the forward step for each neuron. This forward step multiplies the weights by the input, which is received by the `__call__` function and passed to the neuron initialization in the `[neuron(x) for neuron in self.neurons]` line.

Next step now it is to create multiple layers.

    import random

    class Neuron:
        def __init__(self, nin):
            self.w = [value(random.uniform(-1,1)) for _ in range(nin)]
            self.b = random.uniform(-1,1)

        #Forward pass of this neuron
        def __call__(self, x):
            act = sum((wi * xi for wi , xi in list(zip(self.w, x))), self.b)
            out = act.tanh()
            return out
            #return w_x[0] if len(x_w) == 1

    class Layer: 
        def __init__(self, nin, nout):
            """
            Layer initialization class
            
            This function will create a list of neurons based on the input arguments. These neurons will be used in the call function later.

            Args
            nin: Input dimensionallity, for example in this case it X is 3
            nout: Number of neurons that I want to create
            """
            self.neurons = [Neuron(nin) for _ in range(nout)]

        def __call__(self, x):
            """
            Function to call the neurons created in the initialization and apply forward pass

            Args
            x: Input values
            """
            out = [neuron(x) for neuron in self.neurons]
            return out
        
    class MLP:
        def __init__(self, nin, nouts):
            """
            This function initiallize the numbers of layers required

            Args
            nin: Input dimensionallity, necessary to initiallize each neuron weights
            nouts: list of neurons per layer, it will define how many layers and neurons are needed
            """
            sz = [nin] + nouts  
            self.layers = [Layer(sz[i], sz[i+1]) for i in range(len(nouts))]

        def __call__(self, x):
            for layer in self.layers:
                x = layer(x) 
            return x

    x = [1.3, 2.1, 1.7]
    l = MLP(3, [5, 5, 1])
    l(x)

Again two functions were created, the first `__init__` function helps to initiallize multiple layers and the `__call__` function is to use this layers, call them one by one, send the input to each layer and multiply the values by the weight of each neuron.

One thing that took me a while to understand was this line: `self.layers = [Layer(sz[i], sz[i+1]) for i in range(len(nouts))]`. It was quite confusing for me to understand why `sz[i]` and `sz[i+1]` are sent for the layer creation. I'll try to explain it in detail so I don't forget it later.

If I execute just the init function with prints, I'll get this:

    class MLP:
        def __init__(self, nin, nouts):
            """
            This function initiallize the numbers of layers required

            Args
            nin: Input dimensionallity, necessary to initiallize each neuron weights
            nouts: list of neurons per layer, it will define how many layers and neurons are needed
            """
            sz = [nin] + nouts  
            print(f"{sz=}")
            #layers = [Layer(sz[i], sz[i+1]) for i in range(len(nouts))]
            print(f"{len(nouts)=}")
            for i in range(len(nouts)):
                print(f"{i=}")
                print(f"{sz[i]=}")
                print(f"{sz[i+1]=}")

    x = [1.3, 2.1, 1.7]
    l = MLP(3, [5, 5, 1])
    
    ###Print results 

    sz=[3, 5, 5, 1]
    len(nouts)=3
    i=0
    sz[i]=3
    sz[i+1]=5
    i=1
    sz[i]=5
    sz[i+1]=5
    i=2
    sz[i]=5
    sz[i+1]=1

Initially, sz is simply a combination of the two parameters received into a single variable [3, 5, 5, 1]. I printed the length of nouts to ensure that I would create exactly 3 layers based on the length of the nouts list received as an argument. The confusion arose when sz[i] was sent, instead of sz[0], as the first parameter to the layer class. This first parameter is used as the dimensionality sent to the neuron to initialize the weights. In my confusion, I thought it had to be "3" (sz[0]) because I knew the input size was 3, so I assumed that 3 should have been sent all the time. However, I eventually realized that the input dimensionality is only important for the first hidden layer. After the first hidden layer, the weight dimensionality is determined based on the matrix multiplication between weights and neurons.  


## Matrix multiplication

Matrix multiplication is executed as follows. Consider a 3x5 matrix A and a 5x5 matrix B. The resulting matrix C will be a 3x5 matrix. Each element c_ij in matrix C is calculated by taking the dot product of the i-th row of matrix A and the j-th column of matrix B. For example:

    #if A is:
    A = [[a11, a12, a13, a14, a15],
        [a21, a22, a23, a24, a25],
        [a31, a32, a33, a34, a35]]

    #and B is:
    B = [[b11, b12, b13, b14, b15],
        [b21, b22, b23, b24, b25],
        [b31, b32, b33, b34, b35],
        [b41, b42, b43, b44, b45],
        [b51, b52, b53, b54, b55]]

Then the element c_11 in matrix C is calculated as:

    c_11 = a11*b11 + a12*b21 + a13*b31 + a14*b41 + a15*b51

This process is repeated for each element in the resulting matrix C, and as results I'll have a 5x5 matrix, it means that I will keep just the border values of the multiplication, in this case I had 3x5 * 5x5 = 3x5.


## Neuronal Network and matrix multiplication

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_ai_matrix_multiplication.png">


## Using the neuronal network

To use the neural network, I defined a small example with `x` as the input and `y` as the desired output. If I test this input in the neural network, I should get some values as a result and evaluate them with respect to the desired values. This evaluation, or the result of this evaluation, is the famous `loss`, which is basically a number that summarizes how far I am from the correct value, and it is the value that I would look to improve. How would I improve this value, is updating the weights in the gradient direction.

    - Input values:

        xs = [
            [2.0, 3.0, -1.0],
            [3.0, -1.0, 0.5],
            [0.5, 1.0, 1.0],
            [1.0, 1.0, -1.0]
            ]
        ygt = [1.0, -1.0, -1.0, 1.0]

    - Prediction and loss function:

        y_pred = [n(x) for x in xs]
        loss = sum((ygt - yout)**2 for ygt, yout in list(zip(ygt, y_pred)))
        loss
        Value(data=0.532236287306165, grad=0)

    - y_pred print shows how far I'm from the expected results, for example the 4th value expected was 1 and I got 0.4:

        [Value(data=0.8064287379130923, grad=0),
        Value(data=-0.6474686238433255, grad=0),
        Value(data=-0.8794661119331961, grad=0),
        Value(data=0.4033764466157684, grad=0)]

    - loss.backward() to calculate gradient and see how they affect the loss value:

        loss.backward()

    - Update parameters base on the gradients:

        # update parameters
        for p in n.parameters():
            p.data -= 0.01 * p.grad


To update parameters, I had to include the parameters method in the neurons, layers, and MLP classes. This method will return a list with all the parameters to be updated.

        class Module:

            def parameters(self):
                return []

        class Neurons(Module):

            def __init__(self, nin, nonlin=True):
                self.w = [value(np.random.uniform(-1,1)) for _ in range(nin)]
                self.b = value(0)
                self.nonlin = nonlin

            def __call__(self, x):
                act = sum((wi*xi for wi,xi in zip(self.w, x)), self.b)
                return act.relu() if self.nonlin else act
            
            def parameters(self):
                return self.w + [self.b]
            
            def __repr__(self):
                return f"{'ReLU' if self.nonlin else 'Linear'}Neuron({len(self.w)})"
            
        class Layer(Module):

            def __init__(self, nin, nout, **kwargs):
                self.neurons = [Neurons(nin, **kwargs) for _ in range(nout)]

            def __call__(self, x):
                outs = [n(x) for n in self.neurons]
                return outs[0] if len(outs) == 1 else outs
            
            def parameters(self):
                return [p for n in self.neurons for p in n.parameters()]    
            
            def __repr__(self):
                return f"Layer of [{', '.join(str(n) for n in self.neurons)}]"

        class MLP(Module):

            def __init__(self, nin, nouts):
                sz = [nin] + nouts
                self.layers = [Layer(sz[i], sz[i+1], nonlin=i!=len(nouts)-1) for i in range(len(nouts))]

            def __call__(self, x):
                for layer in self.layers:
                    x = layer(x)
                return x

            def parameters(self):
                return [p for layer in self.layers for p in layer.parameters()]

            def __repr__(self):
                return f"MLP of [{', '.join(str(layer) for layer in self.layers)}]"

And to run this process automatically a for loop will be enough:

    for k in range(20):

    #forward pass
    y_pred = [n(x) for x in xs]
    loss = sum((ygt - yout)**2 for ygt, yout in list(zip(ygt, y_pred)))

    #backward pass
    for p in n.parameters():
        p.grad = 0
    loss.backward()

    #update parameters
    for p in n.parameters():
        p.data += -0.05 * p.grad

    print(k, loss.data)


This text Has been wrotte with the main goal of keepin a source of knowledge for my self of the future, to have an space to come back and refresh important concepts that I've learnt during this last time.

All this explanation and learning were thanks to the Andrej Karpathy videos on YouTube, which are great material, very well explained, and hands-on. I've been doing several courses from coursera and others platforms, but this one was the best one in my personal opinion, that what I used now and tried to make it like mine own version of it jaja.
