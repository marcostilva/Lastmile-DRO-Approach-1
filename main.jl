#########################################################################
# Module to  run DDU STOCHASTIC VRP OD

using JuMP, CPLEX #, Distributions
#using LightGraphs,Cairo, Fontconfig,Compose,GraphPlot, Colors,Plots

original_sum = sum

include("../src/data.jl")
include("../src/OptBBfunctions.jl")
include("../src/Utilfunctions.jl")


#Print results to file
appfolder = dirname(@__FILE__) * "/../"   #get current folder
filname=appfolder* "/result/"*"RESULT"*string(now())*".txt"  #define filename to be written
resultado = open(filname, "a")                            #opens file

#Read instance
#XENIA:  INSERT HERE INSTANCES TO RUN. INSTANCES ARE HARD CODED IN data.jl
instances =["8A"]#,"6B","6C","6D","7A","7B","7C","7D"]#,"8A","8B","8C","8D"]#,"9A","9B","9C","9D"]#,"10A","10B","10C","10D","11A","11B","11C","11D","12A","12B","12C","12D"] 
instance = []

for inst_id in instances
V,A,DESTC,PROBC,REGV,REWV,CAPV,DESTOD,PROBOD2,REWOD2,PROBOD,REWOD,CAPOD = read_data(instance, inst_id)


##################################################################################################################################


global heursol = 0
global initialsol = []
global NODECOUNT = 0
global ROUTCOUNT = 0
global COMPCOUNT = 0
global NOROUTCOUNT = 0
global NOCOMPCOUNT = 0
global TimeMain = 0
global TimePric = 0
global TimeSce = 0
tic()
#DDUEXACTV2: independent, tsp; recourse skips outsourced customers plus detour, BOOLEAN COMPENSATION LEVEL, extended formulation with exact column generation
#DDUEXACTV2: Generates all routes, all compensations and solve complete extended formulation
result,initialsol= solveSTODDUEXACTV2(REGV,V,A,DESTC,PROBC,REWV,CAPV,DESTOD,PROBOD,REWOD,PROBOD2,REWOD2,CAPOD)
TimeMain += toq()
println(resultado,inst_id,";","DDUEXACTV2= ",";",result,";",TimeMain+TimePric,";",TimeMain,";",TimePric,";",";",TimeSce,";",NODECOUNT,"; ",ROUTCOUNT,"; ",COMPCOUNT,"; ",NOROUTCOUNT,"; ",NOCOMPCOUNT)
println("Final Solution DDU Stochastic EXACTV2= ",inst_id," ,", result,"  Time spent = ",TimeMain+TimePric,"  Time Main = ",TimeMain,"  Time Pric = ",TimePric,"  Time Comp = ",TimeSce," Nodes =",NODECOUNT,"; ",ROUTCOUNT,"; ",COMPCOUNT,"; ",NOROUTCOUNT,"; ",NOCOMPCOUNT)
#read(STDIN,Char)
#####################################################################################################################################


end
close(resultado)




