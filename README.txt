En el comienzo de cada fichero fuente podemos encontrar los datos de la pr�ctica.
A continuaci�n vienen los pasos para una posible ejecuci�n. Para mayor facilidad se copian a continuaci�n.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% mapReduce %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pasos a seguir para una posible ejecuci�n.

 % Moverse a la ruta donde se encuentre el "mapReduce.erl".
cd(".").

 % Compilar el fichero para generar el archivo con extensi�n beam.
c(mapReduce).

 % Llamar a la funci�n m�ster del m�dulo con los datos deseados (se proporciona el ejemplo 2 en este caso) y recoger en una variable su Pid.
Master = mapReduce:master(mapReduce:datos2(), 3).

 % Se env�a al Pid del m�ster el mensaje con la orden, que contiene las funciones map y reduce (tambi�n proporcionadas con el ejemplo 2).
Master ! {mapreduce, self(), mapReduce:map2(), mapReduce:reduce2()}.

 % Realizamos un vaciado del buz�n del proceso desde el que se ha enviado la orden y podremos visualizar el resultado (en forma de diccionario, como se especifica).
flush().

 % Aqu� veremos como en el buz�n ten�amos el diccionario con los resultados de la ejecuci�n.
 % Se puede probar a utilizar los datos del ejemplo proporcionado en el enunciado de la pr�ctica, solo hay que cambiar el 2 por el 1 en las funciones que se llaman mapReduce:datos2(), mapReduce:map2() y mapReduce:reduce2().



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% mapReduceOpcional %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pasos a seguir para una posible ejecuci�n.

 % Moverse a la ruta donde se encuentre el "mapReduceOpcional.erl". Este paso es opcional.
cd(".").

 % Compilar el fichero para generar el archivo con extensi�n beam.
c(mapReduceOpcional).

 % Llamar a la funci�n m�ster del m�dulo con los datos deseados (se proporciona el ejemplo 2 en este caso) y recoger en una variable su Pid.
Master = mapReduceOpcional:master(mapReduceOpcional:datos2(), 3).

 % Se env�a al Pid del m�ster el mensaje con la orden, que contiene las funciones map y reduce (tambi�n proporcionadas con el ejemplo 2).
Master ! {mapreduce, self(), mapReduceOpcional:map2(), mapReduceOpcional:reduce2()}.

 % Probar el resultado de a�adir un nodo con m�s datos.
mapReduceOpcional:datos2addicionales(Master).
Master ! {mapreduce, self(), mapReduceOpcional:map2(), mapReduceOpcional:reduce2()}.

 % Probar el resultado de eliminar un nodo.
mapReduceOpcional:datos2borrado(Master).
Master ! {mapreduce, self(), mapReduceOpcional:map2(), mapReduceOpcional:reduce2()}.

 % Realizamos un vaciado del buz�n del proceso desde el que se ha enviado la orden y podremos visualizar el resultado (en forma de diccionario, como se especifica). {mapreduce, self(), mapReduce:map2(), mapReduce:reduce2()}.
flush().

 % Aqu� veremos como en el buz�n ten�amos los diccionarios con los resultados de las 3 ejecuciones.


