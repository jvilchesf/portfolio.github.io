---
title: "[Bigram Language Model Part 1] Counting frequence of  characters and predict"
excerpt: "Predict the next character based on the character behind, with a look up table of counts.<br/><img src='https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/potfolio_ai_bigram_frontpage.png' width= 300 height= 300> "
collection: portfolio
---

# Overview

In this section, I want to preserve some knowledge about the bigram model, which is a simple neural network application used to predict the next character in a word based on a previous character. I'll use PyTorch for this.

This text is based on Andrej Karpathy's video, where he explained very interesting and useful concepts in an interactive and hands-on way.

# Start

## Dataset Presentation

The example this time is based on a dataset containing 32,000 different names. The idea is to generate new names based on this dataset.

### Print of the data

Example of first 10 names:

        #print of words, I can see a list
        words[:10]

        ['emma',
        'olivia',
        'ava',
        'isabella',
        'sophia',
        'charlotte',
        'mia',
        'amelia',
        'harper',
        'evelyn']

### Creating dataset

'''
The bigram model predicts the third character based on the previous two. To represent this and create the X and Y datasets, I've copied and understood this Python code. If I see it for the first time, the most challenging part to understand was what the zip function was doing. It essentially takes two iterators (a list is a type of iterator) and pairs their elements together. When one iterator is longer, it stops. For example, with the word "emma", it iterates over ['e', 'm', 'm', 'a'] and ['m', 'm', 'a']. If I align them like a stack, I would get something like:
'''


<img src = '/images/portfolio_ai_bigram_zip_example.png' width = 400 height = 350>
'''

        for word in words[:3]:
            for ch1, ch2 in zip(word, word[1:]):
                print(ch1, ch2)

        e m
        m m
        m a
        o l
        l i
        i v
        v i
        i a
        a v
        v a

By adding characters at the beginning and end of each word, it is possible to extract more data. This approach not only generates a large list of character pairs but also indicates when a word starts and ends, as well as which characters are more common at the beginning and end of a word. It would look like this.

        for word in words[:1]:
        chs = ['<S>'] + list(word) + ['<E>']
        print(f"{chs=}")
        for ch1, ch2 in zip(chs, chs[1:]):
            print(ch1, ch2)

        chs=['<S>', 'e', 'm', 'm', 'a', '<E>']
        <S> e
        e m
        m m
        m a
        a <E>

To understand which characters are likely to follow others, the simplest approach in bigram models is to count their occurrences. I would keep track of how often these combinations appear in the text using a type of dictionary. This dictionary would record the frequency of each character combination.

        big_dict = {}
        for word in words[:3] :
            chs = ['<S>'] + list(word) + ['<E>']
            for ch1, ch2 in zip(chs, chs[1:]):
                bigram = (ch1,ch2)
                big_dict[bigram] = big_dict.get(bigram, 0) +1

        big_dict
        {('<S>', 'e'): 1,
        ('e', 'm'): 1,
        ('m', 'm'): 1,
        ('m', 'a'): 1,
        ('a', '<E>'): 3,
        ('<S>', 'o'): 1,
        ('o', 'l'): 1,
        ('l', 'i'): 1,
        ('i', 'v'): 1,
        ('v', 'i'): 1,
        ('i', 'a'): 1,
        ('<S>', 'a'): 1,
        ('a', 'v'): 1,
        ('v', 'a'): 1}

Okay, how does this work? As I saw before, it is possible to create a bigram variable with zip. Now, I will save this bigram variable in a dictionary, and each time I find 
this bigram in the dictionary, I'll add 1. For example, the bigram `('a', '<E>')` appears 3 times. The first time this bigram passes through the for loop, the dictionary
`big_dict[('a', '<E>')]` is initialized to 0 + 1. The second time it passes through the for loop, `big_dict[('a', '<E>')]` is found and incremented by 1 again, and so on.

### Matrix of character occurrence
Now, it is much better to save this data in a matrix or two dimensional array, where the rows are going to be the first character and the column will be the second character. This two dimensional array will show us how ofthen the second character (column) comes after the first character (rows). 

To create this matrix, I'll be using PyTorch, a popular library for working with arrays and neural networks.

First, I need to gather all the characters from the text. I'll do this by joining all the text in the `words` variable into one long string using `''.join(words)`. Then, I'll 
use a set to remove duplicates, transform it into a list, and sort it to get a final list of all the characters in the text.

The second step is to create a dictionary to map each character to a number. This is a simple and basic form of a tokenizer. The `enumerate` function will provide us with an iterator 
(list) containing the index and the actual value of the list.

In the third step, we'll use this dictionary to encode the characters in the matrix and count their occurrences. I'll evaluate each word with the first "for" loop and create
a `chs` variable to add special characters. With a second "for" loop, I'll go through pairs of characters in the evaluated word, transforming these two characters into numbers 
using the "string to integer" dictionary. The first character will be the row, and the second will be the column. For example, with "Emma" the first pair evaluated is "Em" 
where "E" is a row and "m" is a column. Each time this combination of characters is found in the loop, the matrix cell at position (x, i) will increase by 1.

    import torch
    # To create the array that will save the data
    N = torch.zeros((28,28), dtype = torch.int32)

    #All possible characters in the text
    chars = sorted(list(set(''.join(words))))

    #String to integer
    stoi = { s: i for i,s in enumerate(chars)}
    #Add special characters at the end
    stoi['<S>'] = 26
    stoi['<E>'] = 27

    #Create matrix
    for word in words:
        chs = ['<S>'] + list(word) + ['<E>']
        for ch1, ch2 in zip(chs, chs[1:]):
            xi = stoi[ch1] # row
            xj = stoi[ch2] #column
            N[xi,xj] += 1

### Matrix visualization

Now I'll show how this matrix of values looks like, the only thing is that I had to make some changes for the special characters, nothing big, I just replaced the `'<S>'` and `'<E>'`
by `.` in the dicionary. 

To visualize the matrix, I won't go through much detail about the code, but basically, with matplotlib, I used imshow to create the table, and with a double for loop, I went through this 
visualization and wrote the data that was saved in the count matrix 'N'.

The most important part, it is that now is possible to see what characters are more often together in the list of names.

    import matplotlib.pyplot as plt

    plt.figure(figsize=(16,16))
    plt.imshow(N, cmap = 'Blues')
    for i in range(27):
        for j in range(27):
            chstr = itos[i] + itos[j]
            plt.text(j , i , chstr, ha = "center", va = "bottom", color = 'grey')
            plt.text(j , i , N[i,j].item(), ha = "center", va = "top", color = 'grey')
    plt.title('Character Bigram Occurrence Matrix')
    plt.xlabel('Next Character')
    plt.ylabel('Previous Character')
    plt.show()

<img src = "/images/portfolio_ai_bigram_count_matrix.png">

## Sample using this matrix probabilites

To sample from this matrix or distribution, I'll take the first row as an example. The first row represents the probabilities of each character as the starting character of a name. Remember the first row save the '.' character that represent start point of a word, and the column represent the next character after '.'.

Then I can take this first row and normalize it, which means for each cell in the first row of this matrix (i, j = 1, j), I'll divide it by the sum of the entire row. it is showing me numerically how probably is this character to start a word.

        #Print first row
        N[0]

        tensor([   0, 4410, 1306, 1542, 1690, 1531,  417,  669,  874,  591, 2422, 2963,
        1572, 2538, 1146,  394,  515,   92, 1639, 2055, 1308,   78,  376,  307,
         134,  535,  929,    0], dtype=torch.int32)

        # Transform to float and normallize
        p = N[0].float()
        p = p / p.sum()
        p

        tensor([0.0000, 0.1377, 0.0408, 0.0481, 0.0528, 0.0478, 0.0130, 0.0209, 0.0273,
        0.0184, 0.0756, 0.0925, 0.0491, 0.0792, 0.0358, 0.0123, 0.0161, 0.0029,
        0.0512, 0.0642, 0.0408, 0.0024, 0.0117, 0.0096, 0.0042, 0.0167, 0.0290,
        0.0000])

        # Set up the figure with a larger size for better visibility
        plt.figure(figsize=(10, 0.5))

        # Display the probability distribution as an image
        plt.imshow(p.unsqueeze(0), aspect='auto', cmap='Blues')

        # Annotate each column with the corresponding character
        for i in range(27):
            plt.text(i, 0, itos[i], ha="center", va="bottom", color='grey')  # Added missing '0' for y-coordinate

        # Add labels and title for clarity
        plt.title('Probability Distribution of Starting Characters')
        plt.xlabel('Character Index')

        # Show the plot
        plt.show()

<img src = "/images/portfolio_ai_bigram_first_row_distri.png">

I can now see graphically that the probabilities for a name to start with `a` are very high, unlike the character `u` for example.

Using this matrix distribution as an input for the `torch.multinomial` function is how I will create names. How? What this multinomial function does is essentially take probabilities and return integers that correspond to the probability distribution.

A simple example for torch.multinomial() is the next, I will create a pytorch list with 5 float values representing probabilites for each number, of course it has to sum 1 (normalization). And then what I'll ask to multimodal is to return values between 0 and 4, considering the probabilites of each of them to be sampled.

    p = torch.rand(5)
    p = p / p.sum()
    print(f"The tensor with 5 numbers that sum 1 is: {p}")
    samples = torch.multinomial(p, num_samples = 10, replacement= True)
    print(f"The samples generated based on the distribution in p is {samples}")

    The tensor with 5 numbers that sum 1 is: tensor([0.0496, 0.3026, 0.2348, 0.1440, 0.2691])
    The samples generated based on the distribution in p is tensor([1, 4, 1, 2, 4, 2, 1, 1, 1, 4])

Because the probability of getting the number "1" was 0.3026, higher than the rest, I got more numbers ones sampled.

### Use of torch.multinomial

To use the count matrix to generate names, I will use `torch.multinomial` and the `N matrix`. This code uses a while loop to create a word, generating characters until it generates the character 0 or '.'. It starts with the first row, generating any character depending on the probabilities. After that, the newly generated character will be used next. In terms of the matrix, I will move to the row of the newly generated character and create or generate a new character based on the probabilities of this row, and so on. 

    for i in range(10):

        out = []
        ix = 0
        while True:
            P = N[ix].float()
            ix = torch.multinomial(P, replacement = True, num_samples = 1).item()
            out.append(itos[ix])
            if ix == 0:
                break   
        print(''.join(out))

    nasainofr.
    hrcoeelyvon.
    fith.
    mebisiack.
    rie.
    vigeti.
    elia.
    jadaxtay.
    asa.
    kana.
