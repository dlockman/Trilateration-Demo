from math import *
from numpy import *
from numpy import linalg as LA
from numpy import cross as Cross
from lmfit import minimize, Parameters

# class Trilateration:
#     point_data = {'B9407F30-F5F8-466E-AFF9-25556B57FE6D5362634111': array([.3, 0, 1]),
#     'B9407F30-F5F8-466E-AFF9-25556B57FE6D2506132695': array([1.3, 4.2, 1]),
#     'B9407F30-F5F8-466E-AFF9-25556B57FE6D4318862110': array([2.75, 0, 1])
#     }

#     distance_data = [1,4,3.5]
#     identifiers = ['B9407F30-F5F8-466E-AFF9-25556B57FE6D5362634111',
#     'B9407F30-F5F8-466E-AFF9-25556B57FE6D2506132695',
#     'B9407F30-F5F8-466E-AFF9-25556B57FE6D4318862110']

def trilaterate(point_data, distance_data,identifiers):

    P1 = point_data[identifiers[0]]
    P2 = point_data[identifiers[1]]
    P3 = point_data[identifiers[2]]

    #dist = array([2,2.5,3])
    dist = distance_data

    #from wikipedia
    #transform to get circle 1 at origin
    #transform to get circle 2 on x axis
    ex = (P2 - P1)/(LA.norm(P2 - P1))
    i = dot(ex, P3 - P1)
    ey = (P3 - P1 - i*ex)/(LA.norm(P3 - P1 - i*ex))
    ez = Cross(ex,ey)
    d = LA.norm(P2 - P1)
    j = dot(ey, P3 - P1)

    #from wikipedia
    #plug and chug using above values
    x = (pow(dist[0],2) - pow(dist[1],2) + pow(d,2))/(2*d)
    y = ((pow(dist[0],2) - pow(dist[2],2) + pow(i,2) + pow(j,2))/(2*j)) - ((i/j)*x)

    # only one case shown here
    #z = sqrt(pow(dist[0],2) - pow(x,2) - pow(y,2))

    #triPt is an array with ECEF x,y,z of trilateration point
    triPt = P1 + x*ex + y*ey
    return triPt

def trilaterateLM(point_data,distance_data,identifiers):
    
    mapped_points = empty([len(distance_data),3])
    
    for idx, val in enumerate(identifiers):
        mapped_points[idx] = point_data[identifiers[idx]]
    #numpy.nditer(a, flags=['f_index'], op_flags=['readonly'])
    # while not it.finished:
    #     mapped_points[it.index] = point_data[identifiers[it.index]]

    firstGuess = trilaterate(point_data,distance_data,identifiers)

    params = Parameters()
    params.add('x', value=firstGuess[0], vary=True, min=0)
    params.add('y', value=firstGuess[1], vary=True, min=0)
    params.add('z', value=firstGuess[2], vary=True, min=0)

    estimation = minimize(objective, params, args=(mapped_points, distance_data))
    return estimation

def objective(params, mapped_points, distance_data):
    x = params['x'].value
    y = params['y'].value
    z = params['z'].value

    guess = array([x,y,z])
    print('Guess')
    print guess
    model = empty([len(distance_data)])
    for idx, val in enumerate(mapped_points):
        model[idx] = linalg.norm(guess - mapped_points[idx])
    error = array(distance_data-model)
    print('Error')
    print error
    weightedError = error/array([pow(x,2.0) for x in distance_data])
    print('WeightedError')
    print weightedError
    return weightedError



