En el comienzo de cada fichero fuente podemos encontrar los datos de la práctica.
A continuación vienen los pasos para una posible ejecución. Para mayor facilidad se copian a continuación.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% mapReduce %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pasos a seguir para una posible ejecución.

 % Moverse a la ruta donde se encuentre el "mapReduce.erl".
cd(".").

 % Compilar el fichero para generar el archivo con extensión beam.
c(mapReduce).

 % Llamar a la función máster del módulo con los datos deseados (se proporciona el ejemplo 2 en este caso) y recoger en una variable su Pid.
Master = mapReduce:master(mapReduce:datos2(), 3).

 % Se envía al Pid del máster el mensaje con la orden, que contiene las funciones map y reduce (también proporcionadas con el ejemplo 2).
Master ! {mapreduce, self(), mapReduce:map2(), mapReduce:reduce2()}.

 % Realizamos un vaciado del buzón del proceso desde el que se ha enviado la orden y podremos visualizar el resultado (en forma de diccionario, como se especifica).
flush().

 % Aquí veremos como en el buzón teníamos el diccionario con los resultados de la ejecución.
 % Se puede probar a utilizar los datos del ejemplo proporcionado en el enunciado de la práctica, solo hay que cambiar el 2 por el 1 en las funciones que se llaman mapReduce:datos2(), mapReduce:map2() y mapReduce:reduce2().



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% mapReduceOpcional %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pasos a seguir para una posible ejecución.

 % Moverse a la ruta donde se encuentre el "mapReduceOpcional.erl". Este paso es opcional.
cd(".").

 % Compilar el fichero para generar el archivo con extensión beam.
c(mapReduceOpcional).

 % Llamar a la función máster del módulo con los datos deseados (se proporciona el ejemplo 2 en este caso) y recoger en una variable su Pid.
Master = mapReduceOpcional:master(mapReduceOpcional:datos2(), 3).

 % Se envía al Pid del máster el mensaje con la orden, que contiene las funciones map y reduce (también proporcionadas con el ejemplo 2).
Master ! {mapreduce, self(), mapReduceOpcional:map2(), mapReduceOpcional:reduce2()}.

 % Probar el resultado de añadir un nodo con más datos.
mapReduceOpcional:datos2addicionales(Master).
Master ! {mapreduce, self(), mapReduceOpcional:map2(), mapReduceOpcional:reduce2()}.

 % Probar el resultado de eliminar un nodo.
mapReduceOpcional:datos2borrado(Master).
Master ! {mapreduce, self(), mapReduceOpcional:map2(), mapReduceOpcional:reduce2()}.

 % Realizamos un vaciado del buzón del proceso desde el que se ha enviado la orden y podremos visualizar el resultado (en forma de diccionario, como se especifica). {mapreduce, self(), mapReduce:map2(), mapReduce:reduce2()}.
flush().

 % Aquí veremos como en el buzón teníamos los diccionarios con los resultados de las 3 ejecuciones.


