%% coding: latin-1

% Asignatura: Programación Declarativa Aplicada
% Práctica 1: mapReduce Parte Opcional
% Los puntos de las extensiones implenemtados son:
% 	Uso de ETS en lugar de Dict.
% 	Permitir al máster añadir y borrar nodos.
% 	Procesos map paralelos.
% Autor: Adrián Rabadán Jurado

-module(mapReduceOpcional).
-export([master/2, datos1/0, map1/0, reduce1/0, datos2/0, map2/0, reduce2/0, datos2addicionales/1,  datos2borrado/1]).
%-compile(export_all).

% Pasos a seguir para una posible ejecución.

 % Moverse a la ruta donde se encuentre el "mapReduceOpcional.erl". Este paso es opcional.
% cd(".").

 % Compilar el fichero para generar el archivo con extensión beam.
% c(mapReduceOpcional).

 % Llamar a la función máster del módulo con los datos deseados (se proporciona el ejemplo 2 en este caso) y recoger en una variable su Pid.
% Master = mapReduceOpcional:master(mapReduceOpcional:datos2(), 3).

 % Se envía al Pid del máster el mensaje con la orden, que contiene las funciones map y reduce (también proporcionadas con el ejemplo 2).
% Master ! {mapreduce, self(), mapReduceOpcional:map2(), mapReduceOpcional:reduce2()}.

 % Probar el resultado de añadir un nodo con más datos.
% mapReduceOpcional:datos2addicionales(Master).
% Master ! {mapreduce, self(), mapReduceOpcional:map2(), mapReduceOpcional:reduce2()}.

 % Probar el resultado de eliminar un nodo.
% mapReduceOpcional:datos2borrado(Master).
% Master ! {mapreduce, self(), mapReduceOpcional:map2(), mapReduceOpcional:reduce2()}.

 % Realizamos un vaciado del buzón del proceso desde el que se ha enviado la orden y podremos visualizar el resultado (en forma de diccionario, como se especifica). {mapreduce, self(), mapReduce:map2(), mapReduce:reduce2()}.
% flush().





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MASTER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funcionalidad del sistema que se encarga de dividir una lista de datos en fracciones, la 
 % cantidad de fracciones se le especifica por parámetro junto a la lista de información. Las 
 % fracciones son lo más similares posibles, para intentar repartir por igual el trabajo. Después 
 % queda a la espera de peticiones "mapreduce", que se le envían por medio de mensajes, indicando 
 % las funciones map y reduce que se deben ejecutar. También se necesita saber a quíen (qué 
 % proceso) se le enviará la solución del cómputo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MASTER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Inicializa e inicia (crea) el master
 % (proceso) con una lista de valores y el 
 % número de nodos que se quieren crear para 
 % distribuir los datos de la lista.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
master(Info, N) -> 
	spawn(fun()-> iniciaMaster(Info, N) end).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Crea los nodos map (procesos) y reparte
 % la información entre ellos. Luego entra en
 % un bucle para esperar mensajes mapreduce.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
iniciaMaster(Info, N) ->
	InfoPartida = partirListaEnNTrozos(Info, N),
	ListaPidsNodosMap = creaNodosMapYAsignaTareas(InfoPartida, self()),
	bucleMaster(ListaPidsNodosMap).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Bucle que espera mensajes mapreduce. 
 % Cuando le llega un mensaje crea un proceso
 % que envía las funciones map a los nodos, 
 % recibe los resultados y crea los procesos 
 % reduce. Finalmente devuelve el resultado 
 % por mensaje al proceso que se lo pidió al 
 % máster.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bucleMaster(ListaPidsNodos) ->
	receive
		{mapreduce, Parent, Fmap, Freduce} -> % Formato de la petición mapreduce.
			spawn(fun()-> reparteMapReduce(ListaPidsNodos, {mapreduce, Parent, Fmap, Freduce}) end),
			bucleMaster(ListaPidsNodos);
		{borraNodo, NumeroNodo} -> % Borra el nodo por el índice (1 a N).
			Principio = lists:sublist(ListaPidsNodos, 1, NumeroNodo-1 ), % Seleccionamoslos pids del primero al anterior que queremos borrar.
			Final = lists:sublist(ListaPidsNodos, NumeroNodo+1, length(ListaPidsNodos)), % Seleccionamos desde el siguiente nodo al que queremos borrar hasta el final.
			NuevaListaPidsNodos = Principio ++ Final, % Unimos las listas,
			bucleMaster(NuevaListaPidsNodos); % Hacemos la llamada recursiva con la nueva lista (sin el nodo).
		{añadeNodo, ListaValores} -> % Añade un nuevo nodo al final de la lista.
			Self = self(),
			PidNuevoNodo = spawn(fun()-> bucleNodoMap(ListaValores, length(ListaPidsNodos)+1, Self) end), % Se crea otro nodo map.
			bucleMaster(ListaPidsNodos ++ [PidNuevoNodo]) % Hacemos la llamada recursiva con la nueva lista (con el nodo nuevo).
	end.





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROCESO AUXILIAR DEL MÁSTER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funcionalidad del sistema que se encarga de enviar la función map a los nodos creados por el máster. Tras recibir 
 % los resultados del map, crea un diccionario donde mantiene la información de la clave de los resultados map, junto 
 % con el Pid del proceso que se lanza para ocuparse de dicha clave. Si ya hay un proceso creado para la clave 
 % simplemente se le envía la nueva clave para que la mezcle usando la función reduce que se le proporciona al 
 % inicializarse. Por último, manda una señal end para indicar el fin de los envíos de datos y se genera otro 
 % diccionario con los resultados de la fase reduce, que es enviado al Pid del proceso que generó la petición.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROCESO AUXILIAR DEL MÁSTER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Envía la función map a los nodos mediante
 % su pid. Crea un diccionario y lo rellena 
 % mientras le llegan los resultados de la 
 % fase map. Al terminar de recibir estos 
 % resultados, manda una señal a los procesos
 % encargados de la fase reduce indicando que
 % no hay más datos. Recoge los resultados de
 % reduce y envía al pid de los argumentos un
 % diccionario con los datos.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reparteMapReduce(ListaPidsNodosMap, {mapreduce, Parent, Fmap, Freduce}) -> % Los argumentos son la lista de pids de los nodos map, El proceso que hizo la petición y las funciones de map y reduce.
	difundirMensaje(ListaPidsNodosMap, {startmap, self(), Fmap}), % Envía la función map a los nodos map para que la ejecuten sobre sus datos.
	Diccionario = creaNuevoDiccionario(), % Crea un diccionario vacío.
	DiccionarioCompleto = esperaResultadoMapYCreaReduce(Diccionario, Freduce, length(ListaPidsNodosMap)), % Recibe del buzón los resultados del map y crea procesos reduce para ejecutar la función reduce.
	ListaPidReduce = listaValoresDiccionario(DiccionarioCompleto), % Sacamos los pids de los procesos reduce para hacer una difusión de finalización.
	difundirMensaje(ListaPidReduce, 'end'), % Se indica a los procesos reduce que ya no hay más datos.
	ListaResultadoReduce = esperaResultadoReduce(length(ListaPidReduce)), % Se leen tantos mensajes como procesos reduce y se crea la lista de resultados.
	ResultadoDiccionario = listaADiccionario(ListaResultadoReduce), % Se pasa la lista a diccionario.
	Parent ! ResultadoDiccionario. % Se envía el diccionario al pid proporcionado en los parámetros.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función que se encarga de recibir los 
 % mensajes con los resultados del map. Si ya
 % contiene la clave registrada en el 
 % diccionario se envía un nuevo datoa 
 % procesar para el proceso reduce. En caso 
 % contrario, se crea uno nuevo y se reistra.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
esperaResultadoMapYCreaReduce(Diccionario, _Freduce, 0) -> % Caso en el que ya han devuelto todos los nodos map la respuesta (han terminado).
	Diccionario;
esperaResultadoMapYCreaReduce(Diccionario, Freduce, NumeroProcesos) ->
	receive 
		{Clave, Valor} -> % Resultado de un proceso map.
			YaExisteClave = hayClaveDiccionario(Clave, Diccionario), % Se busca si ya hay un proceso reduce asociado a la clave.
			case YaExisteClave of 
				true -> % Caso en el que sí existe.
					PidReduce = dameValorDiccionario(Clave, Diccionario), % Se recupera el pid para mandarle el nuevo dato.
					PidReduce ! {newvalue, Valor},
					esperaResultadoMapYCreaReduce(Diccionario, Freduce, NumeroProcesos); % Llamada recursiva para esperar más datos.
				false -> % Caso en el que no existe.
					Self = self(),
					PidReduce = spawn(fun()-> creaNodoReduce({Self, Freduce, Clave, Valor}) end), % Creación de un nodo reduce con su primer dato.
					NuevoDiccionario = insertaEnDiccionario(Clave, PidReduce, Diccionario), % Creación de un nuevo diccionario que contiene la clave y el pid del proceso que se acaba de crear.
					esperaResultadoMapYCreaReduce(NuevoDiccionario, Freduce, NumeroProcesos) % Llamada recursiva para esperar más datos, con el diccionario actualizado.
			end;
				
		{'end'} -> % Un nodo map ha terminado.
			esperaResultadoMapYCreaReduce(Diccionario, Freduce, NumeroProcesos-1)  % Llamada recursiva que contempla que ahora se esperan resultados de un nodo map menos.
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función que recoge tantos resultados 
 % reduce como procesos reduce se han creado.
 % Se crea y devuelve la lista de resultados.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
esperaResultadoReduce(0) ->
	[];
esperaResultadoReduce(NumeroProcesos) ->
	receive 
		{Clave, Valor} ->
			[{Clave, Valor} | esperaResultadoReduce(NumeroProcesos-1)]
	end.





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODO (MAP) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funcionalidad del sistema que se encarga de filtrar (ejecutar una funcion map) los datos de entrada
 % con los que se le inicializa. Envía una serie de mensajes al pid proporcionado junto a la función 
 % map que debe ejecutar.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODO (MAP) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Dada una lista de listas que contiene los
 % datos de entrada troceados y el pid del
 % master, crea tantos nodos como trozos.
 % Devuelve los pids de los nodos.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
creaNodosMapYAsignaTareas(InfoPartida, PidMaster) ->
	creaNodosMapYAsignaTareasConContador(InfoPartida, 1, PidMaster).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Crea nodos (procesos) y reparte las tareas 
 % de la lista. Devuelve los pids de los 
 % nodos e incluye el número de nodo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
creaNodosMapYAsignaTareasConContador([], _Contador, _PidMaster) ->
	[];
creaNodosMapYAsignaTareasConContador([InfoCabeza | InfoResto], Contador, PidMaster) ->
	PidNodo = spawn(fun()-> bucleNodoMap(InfoCabeza, Contador, PidMaster) end), % Creación del nodo map.
	[PidNodo | creaNodosMapYAsignaTareasConContador(InfoResto, Contador + 1, PidMaster)]. % Concatena y devuelve los pis de los nodos map.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Bucle infinito en el que permanece el 
 % nodo Map. Cuando le llega un mensaje 
 % aplica la función a los datos que tiene y 
 % devuelve al (pid proporcionado) uno a uno 
 % los resultados y finalmente el atomo end 
 % dentro de una tupla.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bucleNodoMap(Info, NumeroDeNodo, PidMaster) ->
	receive
		{startmap, PidParent, Fmap} ->
			ListaResultados = mapPersonalizado(Fmap, Info), % Se ejecuta la función en todos los elementos de la lista y genera una nueva lista.
			enviarElementosDeLista(PidParent, ListaResultados) % Se envían los elementos de la lista de resultados uno a uno al pid del mensaje (parent).
	end,
	bucleNodoMap(Info, NumeroDeNodo, PidMaster). % Llamada recursiva que hace bucle infinito para esperar indefinidamente funciones map a aplicar.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función map personalizada, que está 
 % adaptada para que los valores que se 
 % filtran o ignoran sean aquellos que 
 % devuelve null al aplicar la función.
 % Se generan tantos procesos como elementos 
 % hay en la lista, para realizar las tareas 
 % concurrentemente. Luego se esperan los 
 % resultados para poder devolverlos.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mapPersonalizado(Fmap, Info) ->
	mapPersonalizadoAux(Fmap, Info), % Crea procesos para ejecutar en paralelo la función map sobre los elementos.
	esperaResultadoMap(length(Info)). % Espera los resultados de la fase map.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función que crea procesos para ejecutar en
 % paralelo la función dada sobre cada 
 % elemento de la lista.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mapPersonalizadoAux(_Funcion, []) -> % Caso en el que ya no hay más elementos en la lista.
	ok;
mapPersonalizadoAux(Funcion, [Cabeza | Resto]) -> % Caso en el que se procesa la cabeza de la lista.
	Self = self(),
	spawn(fun() -> Self ! Funcion(Cabeza) end), % Se lanza la función y se envía el resultado al proceso creador.
	mapPersonalizadoAux(Funcion, Resto). % Llamada recursiva.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función que espera a recibir N resultados
 % map.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
esperaResultadoMap(0) -> 
	[];
esperaResultadoMap(N) -> 
	receive
		null -> esperaResultadoMap(N-1); % Se descarta el valor.
		Resultado -> [Resultado | esperaResultadoMap(N-1)] % Se añade el valor a la lista.
	end.





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODO (REDUCE) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funcionalidad del sistema que se encarga de ejecutar la función map sobre los elementos que le llegan,
 % hasta que recibe el mensaje end, que indica el fin del procesamiento. Solo se devuelve la mezcla de 
 % los datos fusionados por medio de la función reduce proporcionada.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODO (REDUCE) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función que se encarga de poner a la 
 % espera de mensajes al proceso y de enviar 
 % el resultado final al destinatario (como 
 % mensaje) al terminar.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
creaNodoReduce({PidMaster, Freduce, Clave, Valor}) -> 
	PidMaster ! bucleNodoReduce(Freduce, Clave, Valor). % Se envía al pid correspondiente el cálculo final.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Bucle de espera para los datos. Se mezclan
 % o unifican con la función reduce con la 
 % que se creó en proceso. Con la llegada del
 % mensaje end se devuelve el resultado 
 % obtenido hasta ese momento y se finaliza.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bucleNodoReduce(Freduce, Clave, ValorActual) -> 
	receive
		{newvalue, ValorNuevo} -> % Caso en el que le llega un dato nuevo que debe introducirse en la función reduce.
			{Clave, ValorFinal} = Freduce(Clave, ValorActual, ValorNuevo), % Nuevo valor devuelto.
			bucleNodoReduce(Freduce, Clave, ValorFinal); % Llamada recursiva del bucle que guarda el nuevo valor.
		'end' -> % Mensaje que indica que se debe finalizar la etapa de reduce.
			{Clave, ValorActual} % Se devuelve el dato.
	end.





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% UTILIDADES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Parte del sistema con funcionalidades varia que pueden ser útiles en otros sistemas similares o no.
 % Los métodos sobre diccionarios están para poderlos sustituir por otros recursos con funcionalidad 
 % similar fácilmente.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% UTILIDADES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Dada una lista "Info" y un número "N", 
 % genera una lista con los fragmentos de la 
 % lista dada troceadas en "N" fragmentos de 
 % la misma longitúd, si es posible. En caso 
 % contrario los más numerosos son los 
 % primeros.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
partirListaEnNTrozos(Info, 1) -> % Si queda solo un trozo por repartir es la propia lista.
	[Info];
partirListaEnNTrozos(Info, N) -> % Si quedan trozos por repartir, seleccionamos la sublista y vamos creando recursivamente la lista de trozos.
	ParteEntera = length(Info) div N,
	ParteReal = length(Info) / N,
	
	case ParteReal == ParteEntera of
		
		true -> % Como la división de las partes da justa cogemos tantos elementos como indique.
			SublistaCabeza = lists:sublist(Info, ParteEntera);
		
		false -> % Como algunos nodos van a tener más elementos que otros comenzamos asignando uno más a los primeros.
			SublistaCabeza = lists:sublist(Info, ParteEntera+1)
	end,
	
	SublistaResto = lists:sublist(Info, length(SublistaCabeza)+1, length(Info)), % Lista que contiene el resto de datos al quitar los que ya se han adjudicado. Aunque se pide length(Info) elementos, en realidad, solo quedan los restantes.
	
	[SublistaCabeza | partirListaEnNTrozos(SublistaResto, N-1)]. % Adjudicar el resto de trozos de la misma manera.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Envía a cada pid de la lista el mensaje.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
difundirMensaje([], _Mensaje) ->
	ok;
difundirMensaje([PidNodoMapActual | RestoPids], Mensaje) ->
	PidNodoMapActual ! Mensaje,
	difundirMensaje(RestoPids, Mensaje).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Crea y devuelve un nuevo diccionario.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
creaNuevoDiccionario() ->
	ets:new(sinNombre, [set, private, {keypos, 1}]). % Se crea una ETS privada, con clave el primer elemento.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Introduce en el diccionario proporcionado 
 % la clave y el valor.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
insertaEnDiccionario(Clave, Valor, Diccionario) ->
	ets:insert(Diccionario, {Clave, Valor}), % Se inserta en el diccionario la tupla clave-valor, teniendo en cuenta que si la clave ya está, se sobreescribrá el valor.
	Diccionario.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Devuelve si existe la clave en el 
 % diccionario.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hayClaveDiccionario(Clave, Diccionario) ->
	ListaResultados = ets:lookup(Diccionario, Clave), % Se busca la clave y se devuelve una lista de tuplas con la clave y su valor asociado.
	ListaResultados =/= []. % Si se ha devuelto la lista vacía es que no hay elementos guardados con esa clave.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Devuelve el valor asociado a la clave en 
 % el diccionario.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dameValorDiccionario(Clave, Diccionario) -> 
	[{Clave, Valor}] = ets:lookup(Diccionario, Clave), % En nuestro caso no puede haber varios valores asociados a la misma clave, porlo que la lista es unitaria.
	Valor.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Devuelve la lista de los valores 
 % contenidos en el diccionario.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
listaValoresDiccionario(Diccionario) ->
	lists:append(ets:match(Diccionario, {'_', '$1'})). % Se realiza una consulta a la estructura, de forma que se devuelven todos los valores, segundo elemento de la tupla.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función que recorre una lista de tuplas 
 % con clave y valor y recoge únicamente los 
 % valores. EN ESTA VERSIÓN NO ES NECESARIA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%sacaValoresDeLista([]) ->
%	[];
%sacaValoresDeLista([{_Clave, Valor} | RestoDiccionario]) ->
%	[Valor | sacaValoresDeLista(RestoDiccionario)].	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Pasa una lista con tuplas clave-valor a un
 % diccionario.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
listaADiccionario(Lista) ->
	ets:match(listaADiccionarioAux(Lista), {'$1', '$2'}). % Se devuelve una consulta que muestra toda la información de la tabla, ya qe las ETS se pierden al finalizar el proceso creador.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función auxiliar que crea recursivamente
 % una ETS a partir de una lista de tuplas
 % clave-valor.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
listaADiccionarioAux([]) ->
	creaNuevoDiccionario();
listaADiccionarioAux([{Clave, Valor} | Resto]) ->
	insertaEnDiccionario(Clave, Valor, listaADiccionarioAux(Resto)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Envía cada elemento de la lista al pid 
 % proporcionado. Cuando no quedan más 
 % elementos se envía el átomo end en una 
 % tupla y se finaliza.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
enviarElementosDeLista(Pid, []) ->
	Pid ! {'end'};
enviarElementosDeLista(Pid, [Cabeza|Resto]) ->
	Pid ! Cabeza,
	enviarElementosDeLista(Pid, Resto). % Llamada recursiva.










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLOS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % A continuación tenemos una serie de ejemplos, de los que se disponen las funciones datos, map y 
 % reduce seguido del número de ejemplo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLOS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLO1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Ejemplo proporcionado en la descripción de la práctica. Dada una lista de tuplas con ciudades y 
 % temperaturas, filtra las que no superan los 28 grados de máxima y selecciona de esas la que tenga
 % mayor temperatura máxima en cada ciudad.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLO1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Datos del ejemplo 1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
datos1() ->
	[
		{madrid,34},
		{barcelona,21},
		{madrid,22},
		{barcelona,19},
		{teruel,-5},
		{teruel, 14},
		{madrid,37},
		{teruel, -8},
		{barcelona,30},
		{teruel,10}
	].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función map del ejemplo 1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
map1() ->
	fun({Ciudad, Temperatura})->
		if
			Temperatura > 28 ->
				{Ciudad, Temperatura};
			true -> 
				null
		end
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función reduce del ejemplo 1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reduce1() ->
	fun(Clave, ValorAntiguo, ValorNuevo) ->
		case ValorAntiguo > ValorNuevo of
			true ->
				{Clave, ValorAntiguo};
			false ->
				{Clave, ValorNuevo}
		end
	end.





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLO2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Ejemplo extra requerido en la entrega de la práctica. Dada una lista de palabras (pertenecientes 
 % a una frase) selecciona todas ellas y cuenta las apariciones de cada una.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLO2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Datos del ejemplo 2. Datos addicionales y 
 % borrado de un nodo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
datos2() ->
	[
		la,
		jarra,
		está,
		encima,
		de,
		la,
		mesa
	].

datos2addicionales(Master) ->
	Master ! {añadeNodo, [la, la, la]}.

datos2borrado(Master) ->
	Master ! {borraNodo, 1}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función map del ejemplo 2.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
map2() ->
	fun(Palabra)->
		{Palabra, 1}
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Función reduce del ejemplo 2.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reduce2() ->
	fun(Clave, ValorAntiguo, _ValorNuevo) ->
		{Clave, ValorAntiguo + 1}
	end.




