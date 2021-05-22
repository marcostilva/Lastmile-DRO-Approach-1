# Lastmile-DRO-Approach-1
Stochastic crowdshipping last-mile delivery  with correlated marginals

In this work we study last-mile delivery with the option of crowdshipping, where a company makes use
of occasional drivers to complement its fleet in the activity of delivering products to its customers. We
model it as a data-driven distributionally robust optimization approach to the capacitaded vehicle routing
problem, where the marginals of the defined uncertainty vector are known, but the joint distribution is
difficult to estimate. The presence of customers and available occasional drivers can be random. This requests
for a strategic planning perspective, where we calculate an optimal a priori solution before the uncertainty
is revealed. Therefore, without the need for online resolution performance, we can experiment with exact
solutions. Solving the problem defined above is challenging: not only the first-stage problem is already NP-
Hard, but also the uncertainty and potentially the second-stage decisions are binary of high dimension,
leading to non-convex optimization formulations that are complex to solve. We propose algorithms taking into
consideration measures that exploit the intrinsic characteristics of our problem and reduce the complexity
to solve it. We compare solution and time performance of the different algorithms.
