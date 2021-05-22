
#DDUEXACTV2: Generate routes and compensations (options) by column generation
#DDUEXACTV2: independent, decision dependent probabilistic tsp; recourse skips outsourced customers plus detour, BOOLEAN COMPENSATION LEVEL, extended formulation with exact column generation
function solveSTODDUEXACTV2(REGV,V,A,DESTC,PROBC,REWV,CAPV,DESTOD,PROBOD,REWOD,PROBOD2,REWOD2,CAPOD)

  function detour(custpos,orderedcust,PROBCB,PROBC1B) #function used as part of calculation of average cost of a given route and compensation. This function calculates the cost of detour to depot and back to next available customer
    #PROBCB outsourced
    #PROBC1B  not outsourced
    function ff(m,r,orderedcust,PROBCB,PROBC1B) #exactly r customers among the 1,..,m customers are present
      if m == r
        return prod(PROBC1B[orderedcust[1:m]])
      elseif r==0
        return prod(PROBCB[orderedcust[1:m]]) 
      else
        tot = 0
        tot +=PROBC1B[orderedcust[m]]*ff(m-1,r-1,orderedcust,PROBCB,PROBC1B)
        tot +=PROBCB[orderedcust[m]]*ff(m-1,r,orderedcust,PROBCB,PROBC1B)
        return tot
      end
    end

    if custpos<=CAPV-1
      return 0
    else
      summ = 0
      for k in 1:floor(custpos/CAPV)
        summ += ff(custpos-1,k*CAPV-1,orderedcust,PROBCB,PROBC1B) 
      end
      return summ
    end
  end
  
  #########################################################################
  # MAIN PROGRAM for function V2
  #Generate Prices, Routes and Compensations to be used
  #Will also generate all costs at this moment
  ###############################################
  #Create vectors for all possible compensations
  global compensation = Vector{Vector{Int}}() 
  fillscenario(compensation,zeros(length(DESTC)),length(DESTC),1)
  println("Compensations vector created")
  ################################################
  #compensation = []   #This one in case we want to run with just one compensation
  #push!(compensation,zeros(1:length(DESTC)))
  #println(compensation)
  #println(length(compensation))
  #read(STDIN,Char)
  ###############################################
  #Create vectors for all possible routings
  global route = Vector{Vector{Int}}() 
  fillroute(collect(1:length(DESTC)), 1, length(DESTC),route)
  println("Route vectors created")
  ################################################
  #println(length(route))
  #################################################
  #Bypass REWOD and define new prices to pay ODs
  #XENIA: Note that at this moment I am not using the compensation fee (rewod and rewod2) that comes from the data. I am creating my own compensation fee, and I pay one time that (low level) or twice times that (high level).  See why below...
  DESTC1=union(DESTC,[1])
  global PRICEOD
  #Calculate minimum price to pay for ODs
  #This is a critical point. If the OD is available, the model always pays the defined price (or     compensation fee) to the OD, even if the solution is not optimal. To mitigate sub-optimization, we define a minimal price for each customer below. Note that it coul be zero in the case one customer is located exactly in between the straight line of two other customers. So we add a fixed ammount at the end. Since the probabilities are already given in the isntance, we just assume that the prices defined below are coherent with the probabilities defined in the instance. 
  #XENIA: To start with 
  global PRICEOD = Inf*ones(1:length(DESTC))
  for i in DESTC
    for j in DESTC1
      for r in DESTC1
        if (j !=r && j != i && r != i) || (j==1 && r==1)
          if PRICEOD[findfirst(x -> x==i, DESTC)] > REWV*(A[j,i] + A[i,r] - A[j,r])
             PRICEOD[findfirst(x -> x==i, DESTC)] = REWV*(A[j,i] + A[i,r]- A[j,r])
             PRICEOD[findfirst(x -> x==i, DESTC)] +=0.1
          end
        end
      end
    end
  end

  ################################################
  #Not yet Calculate costs
  global cost = zeros(length(route),length(compensation))
  
  #####################################################################
 
    #Initialize routes and compensations to be added. With the lack of better heuristic for incubent solutions just defined ad-hoc routes and compensations now 
  routesused = [1,2,3]
  compensationused = [1,2,3]

  #calculate here upfront the cost coeficient of all feasible solutions and existent scenarios at this time
  #XENIA; Here is how I calculate the average cost of a given route and compenstion vector
  global cost
  for r in routesused
    for c in compensationused
      if cost[r,c] == 0
        #Define compensation and probability Vector 
        #CM = REWOD + REWOD2 .* compensation[c]
        CM = PRICEOD + PRICEOD .* compensation[c]
        PM1 = PROBOD + PROBOD2  .* compensation[c]  #outsourced
        PM = ones(1:length(DESTC)).-PM1    #not outsourced
        #Define Cost Vector
        #############################################################################
        LowerIndenpright=0 
        for i in 1:length(route[r])
          cost[r,c] += CM[route[r][i]]*PM1[route[r][i]]
          cost[r,c] += REWV*A[1,DESTC[route[r][i]]]*PM[route[r][i]]*prod(PM1[route[r][1:i-1]])
          cost[r,c] += REWV*A[DESTC[route[r][i]],1]*PM[route[r][i]]*prod(PM1[route[r][i+1:end]])
          for j in i+1:length(route[r])
            cost[r,c] += REWV*A[DESTC[route[r][i]],DESTC[route[r][j]]]*PM[route[r][i]]*PM[route[r][j]]*prod(PM1[route[r][i+1:j-1]])
            LowerIndenpright += REWV*(A[DESTC[route[r][i]],1]+A[1,DESTC[route[r][j]]]-A[DESTC[route[r][i]],DESTC[route[r][j]]]) *PM[route[r][i]]*PM[route[r][j]]*prod(PM1[route[r][i+1:j-1]])*detour(i,route[r],PM1,PM)
          end
        end
        #############################################################################
        LowerIndenpInv=0
        routeinv=reverse(route[r])
        for i in 1:length(routeinv)
          for j in i+1:length(routeinv)
            LowerIndenpInv += REWV*(A[DESTC[routeinv[i]],1]+A[1,DESTC[routeinv[j]]]-A[DESTC[routeinv[i]],DESTC[routeinv[j]]]) *PM[routeinv[i]]*PM[routeinv[j]]*prod(PM1[routeinv[i+1:j-1]])*detour(i,routeinv,PM1,PM)
          end
        end
        cost[r,c] += min(LowerIndenpright,LowerIndenpInv)
        #print("r= ",r, " c= ", c," , ", cost[r,c], " ;;")
      end #end cost[r,c] == 0
    end
  end


  #Now formulate problem  
  y = Vector{Variable}(length(routesused))  #define vector for y variables
  z = Matrix{Variable}(length(routesused),length(compensationused)) #define matrix for z variables
  const3 = Vector{ConstraintRef}(length(routesused))  #define vector for constraints
   
  model = Model(solver = CplexSolver(CPX_PARAM_SCRIND=0,CPX_PARAM_TILIM=3600))
   
  for r in 1:length(routesused)
    y[r] = @variable(model,  lowerbound = 0, upperbound =1)
  end
  for r in 1:length(routesused), c in 1:length(compensationused)
    z[r,c] = @variable(model,  lowerbound = 0, upperbound =1)
  end

  @objective(model, Min, sum(sum( cost[routesused[r],compensationused[c]]*z[r,c] for r=1:length(routesused)) for c=1:length(compensationused) ))

  @constraint(model, const2, sum( y[r] for r=1:length(routesused))== 1)
   
  for r in 1:length(routesused)
    const3[r]=@constraint(model, sum(z[r,c] for c=1:length(compensationused)) - y[r] == 0)
  end
  
  while true
    status = solve(model)
    global TimeMain += toq()
    tic()
    trueobjective = getobjectivevalue(model)
    #println("Solved node ", current," result is new ",  trueobjective)
     
    if status != :Optimal  #If Not Optimal stop because there is error
      println("Stopped...Not Optimal! ")
      read(STDIN,Char)  
      stop = true
      break 
    end
   
    #Do pricing now
    const2_dual = -getdual(const2)
    const3_dual = [-getdual(const3[r]) for r in 1:length(routesused)]

    #Will consider introducing route columns and then compensation columns
    #First route column              
    routereducedcosts = +Inf #0
    compreducedcosts = 0
    best_r = 0 
    best_c = 0       
    for r in 1:length(route)  #test reduced cost for all new routes 
      routereducedcosts = +Inf #0
      best_r = r
      if !in(r,routesused)
        for c in compensationused
          global cost
          if cost[r,c] == 0
            #Define compensation and probability Vector 
            #CM = REWOD + REWOD2 .* compensation[c]
            CM = PRICEOD + PRICEOD .* compensation[c]
            PM1 = PROBOD + PROBOD2  .* compensation[c]
            PM = ones(1:length(DESTC))-PM1
            #Define Cost Vector
            #############################################################################
            LowerIndenpright=0 
            for i in 1:length(route[r])
              cost[r,c] += CM[route[r][i]]*PM1[route[r][i]]
              cost[r,c] += REWV*A[1,DESTC[route[r][i]]]*PM[route[r][i]]*prod(PM1[route[r][1:i-1]])
              cost[r,c] += REWV*A[DESTC[route[r][i]],1]*PM[route[r][i]]*prod(PM1[route[r][i+1:end]])
              for j in i+1:length(route[r])
                cost[r,c] += REWV*A[DESTC[route[r][i]],DESTC[route[r][j]]]*PM[route[r][i]]*PM[route[r][j]]*prod(PM1[route[r][i+1:j-1]])
                LowerIndenpright += REWV*(A[DESTC[route[r][i]],1]+A[1,DESTC[route[r][j]]]-A[DESTC[route[r][i]],DESTC[route[r][j]]]) *PM[route[r][i]]*PM[route[r][j]]*prod(PM1[route[r][i+1:j-1]])*detour(i,route[r],PM1,PM)
              end
            end
            #############################################################################
            LowerIndenpInv=0
            routeinv=reverse(route[r])
            for i in 1:length(routeinv)
              for j in i+1:length(routeinv)
                LowerIndenpInv += REWV*(A[DESTC[routeinv[i]],1]+A[1,DESTC[routeinv[j]]]-A[DESTC[routeinv[i]],DESTC[routeinv[j]]]) *PM[routeinv[i]]*PM[routeinv[j]]*prod(PM1[routeinv[i+1:j-1]])*detour(i,routeinv,PM1,PM)
              end
            end
            cost[r,c] += min(LowerIndenpright,LowerIndenpInv)
            #print("r= ",r, " c= ", c," , ", cost[r,c], " ;;")
          end
          if  routereducedcosts >  cost[r,c]
            routereducedcosts =  cost[r,c]
          end
        end
        routereducedcosts = routereducedcosts +const2_dual
      end
      routereducedcosts < 0 && break #We look for the first negative reduced cost in order to reduce time spent in pricing problem
    end
    #println("finding routes reducedcost minimal is for ", best_r," result is ",  routereducedcosts)
    #read(STDIN,Char)
    global TimePric += toq()
    tic()
    if routereducedcosts >= 0
     global NOROUTCOUNT += 1 
      #try to find new compensations for the routes already given
      for c in 1:length(compensation)
        if !in(c,compensationused)
          compreducedcosts = +Inf
          best_c = c
          for r in routesused
            global cost
            if cost[r,c] == 0
              #Define compensation and probability Vector 
              #CM = REWOD + REWOD2 .* compensation[c]
              CM = PRICEOD + PRICEOD .* compensation[c]
              PM1 = PROBOD + PROBOD2  .* compensation[c]
              PM = ones(1:length(DESTC))-PM1
              #Define Cost Vector
              #############################################################################
              LowerIndenpright=0 
              for i in 1:length(route[r])
                cost[r,c] += CM[route[r][i]]*PM1[route[r][i]]
                cost[r,c] += REWV*A[1,DESTC[route[r][i]]]*PM[route[r][i]]*prod(PM1[route[r][1:i-1]])
                cost[r,c] += REWV*A[DESTC[route[r][i]],1]*PM[route[r][i]]*prod(PM1[route[r][i+1:end]])
                for j in i+1:length(route[r])
                  cost[r,c] += REWV*A[DESTC[route[r][i]],DESTC[route[r][j]]]*PM[route[r][i]]*PM[route[r][j]]*prod(PM1[route[r][i+1:j-1]])
                  LowerIndenpright += REWV*(A[DESTC[route[r][i]],1]+A[1,DESTC[route[r][j]]]-A[DESTC[route[r][i]],DESTC[route[r][j]]]) *PM[route[r][i]]*PM[route[r][j]]*prod(PM1[route[r][i+1:j-1]])*detour(i,route[r],PM1,PM)
                end
              end
              #############################################################################
              LowerIndenpInv=0
              routeinv=reverse(route[r])
              for i in 1:length(routeinv)
                for j in i+1:length(routeinv)
                  LowerIndenpInv += REWV*(A[DESTC[routeinv[i]],1]+A[1,DESTC[routeinv[j]]]-A[DESTC[routeinv[i]],DESTC[routeinv[j]]]) *PM[routeinv[i]]*PM[routeinv[j]]*prod(PM1[routeinv[i+1:j-1]])*detour(i,routeinv,PM1,PM)
                end
              end
              cost[r,c] += min(LowerIndenpright,LowerIndenpInv)
              #print("r= ",r, " c= ", c," , ", cost[r,c], " ;;")
            end
            if  compreducedcosts >  cost[r,c]
              compreducedcosts =  cost[r,c]
            end
          end
          compreducedcosts = compreducedcosts +const2_dual
        end
        compreducedcosts < 0 && break
      end
      #println("finding compensation reducedcost minimal is for ", best_c," result is ",  compreducedcosts)
      #read(STDIN,Char)
      global NOCOMPCOUNT 
      if  compreducedcosts > -0.001 NOCOMPCOUNT += 1 end 
    end 
    stop = false
    global TimeSce += toq()
    tic()
    if routereducedcosts < -0.0001  #Insert new columns
      global ROUTCOUNT += 1
      push!(routesused,best_r)  #update solutions used
      println("route number ",ROUTCOUNT, " added ",best_r)

      #calculate new costs
      #Insert new variables Y and Z
      push!(y,@variable(model,  lowerbound = 0, upperbound =1, objective = 0.0, inconstraints = [const2], coefficients = [1.0]))
      #Insert new constraints
      const3new =  @constraint(model,  - y[length(routesused)] == 0)
      const3 = [const3;const3new]
      znew = Array{Variable}(1,length(compensationused))
      for c in 1:length(compensationused)
        znew[1,c]=@variable(model,  lowerbound = 0, upperbound =1, objective = cost[best_r,compensationused[c]], inconstraints = [const3[length(routesused)]], coefficients = [1.0])
      end 
      z = [z;znew]
    elseif  compreducedcosts < -0.001
      global COMPCOUNT += 1
      push!(compensationused,best_c)  #update solutions used
      println("comp number ",COMPCOUNT, " added ",best_c)
      #Insert new variables  Z
      znew = Vector{Variable}(length(routesused))
      for r in 1:length(routesused)
        znew[r]=@variable(model,  lowerbound = 0, upperbound =1, objective = cost[routesused[r],best_c], inconstraints = [const3[r]], coefficients = [1.0])
      end 
      z = hcat(z,znew) 
  
    else
      println("solved = ", getobjectivevalue(model))
      stop = true 
    end
    stop && break 
  end 
return getobjectivevalue(model),getvalue(y) 

end
