# MINISpice by Tanmay Bothra (25116100) & Srijan Kumar (25117138)

> Visit the public repository: https://github.com/MTTI-web/minispice
We highly recommend viewing this repo to go through the timeline of building this project through commits.

The app is the solution to all your problems if you're a second year B. Tech. student, taking Sarvana Sir's course called Network Theory. Hopefully he lets us use this in the exam :)

We have used the technique of nodal analysis to generalize the whole circuit into a MNA Matrix that is iteratively updated to accomodate all of elements.

The MNA Matrix essentially represents a set of equations. The number of equations is directly equal to the number of unknown variables.

The core working of the program relies on iterating over each element and updating the conductance matrix accordingly.

Two classes called Node and Element are defined to conveniently store the relevant information about each node and element in the circuit respectively.

## Understanding the netlist

### Voltage Source

`<name>` must start with `V`.

`<name> <positive terminal> <negative terminal> <voltage>`

or

`<name> <positive terminal> <negative terminal> DC <voltage>`

### Current Source

`<name>` must start with `I`.

`<name> <from_node> <to_node> <current>`

or

`<name> <from_node> <to_node> DC <current>`

### Resistance

`<name>` must start with `R`.

`<name> <node_1> <node_2> <resistance>`

### VCVS

`<name>` must start with `E`.

`<name> <positive_terminal> <negative_terminal> <n1> <n2> <gain>`

Here,

$$
V_{\text{positive terminal}} - V_{\text{negative terminal}}
= G \times \left(V_{\text{n1}} - V_{\text{n2}}\right)
$$

where $G$ is gain.

### CCCS

`<name>` must start with `F`.

`<name> <positive_terminal> <negative_terminal> <element> <gain>`

Here,

$$
I_{\text{positive terminal} \rightarrow \text{negative terminal}}
= G \times I_{\text{element}}
$$

where $I_{\text{element}}$ is the current through the element `<element>`, and $G$ is the current gain.

### VCCS

`<name>` must start with `G`.

`<name> <positive_terminal> <negative_terminal> <n1> <n2> <multiplier>`

Here,

$$
I_{\text{positive terminal} \rightarrow \text{negative terminal}}
= G \times \left(V_{\text{n1}} - V_{\text{n2}}\right)
$$

where $G$ is the multiplier.

### CCVS

`<name>` must start with `H`.

`<name> <positive_terminal> <negative_terminal> <element> <multiplier>`

Here,

$$
V_{\text{positive terminal}} - V_{\text{negative terminal}}
= G \times I_{\text{element}}
$$

where $I_{\text{element}}$ is the current through the element `<element>`, and $G$ is the multiplier.

### OpAmp

`<name>` must start with `O`.

`<name> <positive_input> <negative_input> <positive_output> <negative_output>`

OpAmp is an ideal VCVS with infinite gain:

$$
V_{\text{out}}
= A \times \left(V_{\text{positive input}} - V_{\text{negative input}}\right)
$$

where $A \rightarrow \infty$.

For an ideal op-amp operating in its linear region:

$$
V_{\text{positive input}} = V_{\text{negative input}}
$$

and

$$
I_{\text{positive input}} = I_{\text{negative input}} = 0.
$$

## Working of the Progam

### Parsing
The program first takes in the netlist as a text file and parses through it.
   - It removes the comments and other operator commands like `.op`.
   - It goes through each line and stores all the unique nodes in the `nodes` array.
   - It identifies the Element using its identifier (e.g. R for Resistor, E for VCVS) and also stores the corresponding nodes for each element.

Two arrays called elements and nodes are then populated with instances of Node and Element class derived from the netlist.

### Constructing the MNA matrices
The next step is figuring out the dimension of the G-matrix (conductance matrix). This is decided by the number of unknown variables. The following contributes to the dimension of the matrix:
1. total number of unique nodes minus one reference node (unknown: voltage of node)
2. number of voltage sources (unknown: current through voltage source)
3. number of opamps (unknown: current through output node)

$$G_{mat} * V_{mat} = I_{mat}$$

Now, we iterate through element modifying the I_mat and G_mat with the known parameters of the devices. 

The `G_mat` is finally inverted to calculate the unknown variables present in `V_mat`.