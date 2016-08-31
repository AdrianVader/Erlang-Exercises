%% coding: latin-1

% Asignatura: Programaci�n Declarativa Aplicada
% Pr�ctica 1: MapReduce
% Autor: Adri�n Rabad�n Jurado

-module(mapReduce).
-export([master/2, datos1/0, map1/0, reduce1/0, datos2/0, map2/0, reduce2/0]).
%-compile(export_all).

% Pasos a seguir para una posible ejecuci�n.

 % Moverse a la ruta donde se encuentre el "mapReduce.erl".
% cd(".").

 % Compilar el fichero para generar el archivo con extensi�n beam.
% c(mapReduce).

 % Llamar a la funci�n m�ster del m�dulo con los datos deseados (se proporciona el ejemplo 2 en este caso) y recoger en una variable su Pid.
% Master = mapReduce:master(mapReduce:datos2(), 3).

 % Se env�a al Pid del m�ster el mensaje con la orden, que contiene las funciones map y reduce (tambi�n proporcionadas con el ejemplo 2).
% Master ! {mapreduce, self(), mapReduce:map2(), mapReduce:reduce2()}.

 % Realizamos un vaciado del buz�n del proceso desde el que se ha enviado la orden y podremos visualizar el resultado (en forma de diccionario, como se especifica).
% flush().





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MASTER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funcionalidad del sistema que se encarga de dividir una lista de datos en fracciones, la 
 % cantidad de fracciones se le especifica por par�metro junto a la lista de informaci�n. Las 
 % fracciones son lo m�s similares posibles, para intentar repartir por igual el trabajo. Despu�s 
 % queda a la espera de peticiones "mapreduce", que se le env�an por medio de mensajes, indicando 
 % las funciones map y reduce que se deben ejecutar. Tambi�n se necesita saber a qu�en (qu� 
 % proceso) se le enviar� la soluci�n del c�mputo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MASTER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Inicializa e inicia (crea) el master
 % (proceso) con una lista de valores y el 
 % n�mero de nodos que se quieren crear para 
 % distribuir los datos de la lista.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
master(Info, N) -> 
	spawn(fun()-> iniciaMaster(Info, N) end).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Crea los nodos map (procesos) y reparte
 % la informaci�n entre ellos. Luego entra en
 % un bucle para esperar mensajes mapreduce.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
iniciaMaster(Info, N) ->
	InfoPartida = partirListaEnNTrozos(Info, N),
	ListaPidsNodosMap = creaNodosMapYAsignaTareas(InfoPartida, self()),
	bucleMaster(ListaPidsNodosMap).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Bucle que espera mensajes mapreduce. 
 % Cuando le llega un mensaje crea un proceso
 % que env�a las funciones map a los nodos, 
 % recibe los resultados y crea los procesos 
 % reduce. Finalmente devuelve el resultado 
 % por mensaje al proceso que se lo pidi� al 
 % m�ster.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bucleMaster(ListaPidsNodos) ->
	receive
		{mapreduce, Parent, Fmap, Freduce} -> % Formato de la petici�n mapreduce.
			spawn(fun()-> reparteMapReduce(ListaPidsNodos, {mapreduce, Parent, Fmap, Freduce}) end)
	end,
	bucleMaster(ListaPidsNodos).





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROCESO AUXILIAR DEL M�STER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funcionalidad del sistema que se encarga de enviar la funci�n map a los nodos creados por el m�ster. Tras recibir 
 % los resultados del map, crea un diccionario donde mantiene la informaci�n de la clave de los resultados map, junto 
 % con el Pid del proceso que se lanza para ocuparse de dicha clave. Si ya hay un proceso creado para la clave 
 % simplemente se le env�a la nueva clave para que la mezcle usando la funci�n reduce que se le proporciona al 
 % inicializarse. Por �ltimo, manda una se�al end para indicar el fin de los env�os de datos y se genera otro 
 % diccionario con los resultados de la fase reduce, que es enviado al Pid del proceso que gener� la petici�n.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROCESO AUXILIAR DEL M�STER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Env�a la funci�n map a los nodos mediante
 % su pid. Crea un diccionario y lo rellena 
 % mientras le llegan los resultados de la 
 % fase map. Al terminar de recibir estos 
 % resultados, manda una se�al a los procesos
 % encargados de la fase reduce indicando que
 % no hay m�s datos. Recoge los resultados de
 % reduce y env�a al pid de los argumentos un
 % diccionario con los datos.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reparteMapReduce(ListaPidsNodosMap, {mapreduce, Parent, Fmap, Freduce}) -> % Los argumentos son la lista de pids de los nodos map, El proceso que hizo la petici�n y las funciones de map y reduce.
	difundirMensaje(ListaPidsNodosMap, {startmap, self(), Fmap}), % Env�a la funci�n map a los nodos map para que la ejecuten sobre sus datos.
	Diccionario = creaNuevoDiccionario(), % Crea un diccionario vac�o.
	DiccionarioCompleto = esperaResultadoMapYCreaReduce(Diccionario, Freduce, length(ListaPidsNodosMap)), % Recibe del buz�n los resultados del map y crea procesos reduce para ejecutar la funci�n reduce.
	ListaPidReduce = listaValoresDiccionario(DiccionarioCompleto), % Sacamos los pids de los procesos reduce para hacer una difusi�n de finalizaci�n.
	difundirMensaje(ListaPidReduce, 'end'), % Se indica a los procesos reduce que ya no hay m�s datos.
	ListaResultadoReduce = esperaResultadoReduce(length(ListaPidReduce)), % Se leen tantos mensajes como procesos reduce y se crea la lista de resultados.
	ResultadoDiccionario = listaADiccionario(ListaResultadoReduce), % Se pasa la lista a diccionario.
	Parent ! ResultadoDiccionario. % Se env�a el diccionario al pid proporcionado en los par�metros.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funci�n que se encarga de recibir los 
 % mensajes con los resultados del map. Si ya
 % contiene la clave registrada en el 
 % diccionario se env�a un nuevo datoa 
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
				true -> % Caso en el que s� existe.
					PidReduce = dameValorDiccionario(Clave, Diccionario), % Se recupera el pid para mandarle el nuevo dato.
					PidReduce ! {newvalue, Valor},
					esperaResultadoMapYCreaReduce(Diccionario, Freduce, NumeroProcesos); % Llamada recursiva para esperar m�s datos.
				false -> % Caso en el que no existe.
					Self = self(),
					PidReduce = spawn(fun()-> creaNodoReduce({Self, Freduce, Clave, Valor}) end), % Creaci�n de un nodo reduce con su primer dato.
					NuevoDiccionario = insertaEnDiccionario(Clave, PidReduce, Diccionario), % Creaci�n de un nuevo diccionario que contiene la clave y el pid del proceso que se acaba de crear.
					esperaResultadoMapYCreaReduce(NuevoDiccionario, Freduce, NumeroProcesos) % Llamada recursiva para esperar m�s datos, con el diccionario actualizado.
			end;
				
		{'end'} -> % Un nodo map ha terminado.
			esperaResultadoMapYCreaReduce(Diccionario, Freduce, NumeroProcesos-1)  % Llamada recursiva que contempla que ahora se esperan resultados de un nodo map menos.
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funci�n que recoge tantos resultados 
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
 % con los que se le inicializa. Env�a una serie de mensajes al pid proporcionado junto a la funci�n 
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
 % nodos e incluye el n�mero de nodo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
creaNodosMapYAsignaTareasConContador([], _Contador, _PidMaster) ->
	[];
creaNodosMapYAsignaTareasConContador([InfoCabeza | InfoResto], Contador, PidMaster) ->
	PidNodo = spawn(fun()-> bucleNodoMap(InfoCabeza, Contador, PidMaster) end), % Creaci�n del nodo map.
	[PidNodo | creaNodosMapYAsignaTareasConContador(InfoResto, Contador + 1, PidMaster)]. % Concatena y devuelve los pis de los nodos map.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Bucle infinito en el que permanece el 
 % nodo Map. Cuando le llega un mensaje 
 % aplica la funci�n a los datos que tiene y 
 % devuelve al (pid proporcionado) uno a uno 
 % los resultados y finalmente el atomo end 
 % dentro de una tupla.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bucleNodoMap(Info, NumeroDeNodo, PidMaster) ->
	receive
		{startmap, PidParent, Fmap} ->
			ListaResultados = mapPersonalizado(Fmap, Info), % Se ejecuta la funci�n en todos los elementos de la lista y genera una nueva lista.
			enviarElementosDeLista(PidParent, ListaResultados) % Se env�an los elementos de la lista de resultados uno a uno al pid del mensaje (parent).
	end,
	bucleNodoMap(Info, NumeroDeNodo, PidMaster). % Llamada recursiva que hace bucle infinito para esperar indefinidamente funciones map a aplicar.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funci�n map personalizada, que est� 
 % adaptada para que los valores que se 
 % filtran o ignoran sean aquellos que 
 % devuelve null al aplicar la funci�n.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mapPersonalizado(_Funcion, []) -> % Caso en el que ya no hay m�s elementos en la lista.
	[];
mapPersonalizado(Funcion, [Cabeza | Resto]) -> % Caso en el que se procesa la cabeza de la lista.
	Resultado = Funcion(Cabeza),
	case Resultado of
		null -> mapPersonalizado(Funcion, Resto); % Se descarta el valor.
		_Any -> [Resultado | mapPersonalizado(Funcion, Resto)] % Se a�ade el valor a la lista.
	end.





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODO (REDUCE) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funcionalidad del sistema que se encarga de ejecutar la funci�n map sobre los elementos que le llegan,
 % hasta que recibe el mensaje end, que indica el fin del procesamiento. Solo se devuelve la mezcla de 
 % los datos fusionados por medio de la funci�n reduce proporcionada.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODO (REDUCE) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funci�n que se encarga de poner a la 
 % espera de mensajes al proceso y de enviar 
 % el resultado final al destinatario (como 
 % mensaje) al terminar.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
creaNodoReduce({PidMaster, Freduce, Clave, Valor}) -> 
	PidMaster ! bucleNodoReduce(Freduce, Clave, Valor). % Se env�a al pid correspondiente el c�lculo final.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Bucle de espera para los datos. Se mezclan
 % o unifican con la funci�n reduce con la 
 % que se cre� en proceso. Con la llegada del
 % mensaje end se devuelve el resultado 
 % obtenido hasta ese momento y se finaliza.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bucleNodoReduce(Freduce, Clave, ValorActual) -> 
	receive
		{newvalue, ValorNuevo} -> % Caso en el que le llega un dato nuevo que debe introducirse en la funci�n reduce.
			{Clave, ValorFinal} = Freduce(Clave, ValorActual, ValorNuevo), % Nuevo valor devuelto.
			bucleNodoReduce(Freduce, Clave, ValorFinal); % Llamada recursiva del bucle que guarda el nuevo valor.
		'end' -> % Mensaje que indica que se debe finalizar la etapa de reduce.
			{Clave, ValorActual} % Se devuelve el dato.
	end.





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% UTILIDADES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Parte del sistema con funcionalidades varia que pueden ser �tiles en otros sistemas similares o no.
 % Los m�todos sobre diccionarios est�n para poderlos sustituir por otros recursos con funcionalidad 
 % similar f�cilmente.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% UTILIDADES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Dada una lista "Info" y un n�mero "N", 
 % genera una lista con los fragmentos de la 
 % lista dada troceadas en "N" fragmentos de 
 % la misma longit�d, si es posible. En caso 
 % contrario los m�s numerosos son los 
 % primeros.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
partirListaEnNTrozos(Info, 1) -> % Si queda solo un trozo por repartir es la propia lista.
	[Info];
partirListaEnNTrozos(Info, N) -> % Si quedan trozos por repartir, seleccionamos la sublista y vamos creando recursivamente la lista de trozos.
	ParteEntera = length(Info) div N,
	ParteReal = length(Info) / N,
	
	case ParteReal == ParteEntera of
		
		true -> % Como la divisi�n de las partes da justa cogemos tantos elementos como indique.
			SublistaCabeza = lists:sublist(Info, ParteEntera);
		
		false -> % Como algunos nodos van a tener m�s elementos que otros comenzamos asignando uno m�s a los primeros.
			SublistaCabeza = lists:sublist(Info, ParteEntera+1)
	end,
	
	SublistaResto = lists:sublist(Info, length(SublistaCabeza)+1, length(Info)), % Lista que contiene el resto de datos al quitar los que ya se han adjudicado. Aunque se pide length(Info) elementos, en realidad, solo quedan los restantes.
	
	[SublistaCabeza | partirListaEnNTrozos(SublistaResto, N-1)]. % Adjudicar el resto de trozos de la misma manera.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Env�a a cada pid de la lista el mensaje.
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
	dict:new().

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Introduce en el diccionario proporcionado 
 % la clave y el valor.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
insertaEnDiccionario(Clave, Valor, Diccionario) ->
	dict:store(Clave, Valor, Diccionario).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Devuelve si existe la clave en el 
 % diccionario.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hayClaveDiccionario(Clave, Diccionario) ->
	dict:is_key(Clave, Diccionario).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Devuelve el valor asociado a la clave en 
 % el diccionario.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dameValorDiccionario(Clave, Diccionario) -> 
	{ok, Valor} = dict:find(Clave, Diccionario),
	Valor.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Devuelve la lista de los valores 
 % contenidos en el diccionario.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
listaValoresDiccionario(Diccionario) ->
	sacaValoresDeLista(dict:to_list(Diccionario)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funci�n que recorre una lista de tuplas 
 % con clave y valor y recoge �nicamente los 
 % valores.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sacaValoresDeLista([]) ->
	[];
sacaValoresDeLista([{_Clave, Valor} | RestoDiccionario]) ->
	[Valor | sacaValoresDeLista(RestoDiccionario)].	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Pasa una lista con tuplas clave-valor a un
 % diccionario.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
listaADiccionario(ListaResultadoReduce) ->
	dict:from_list(ListaResultadoReduce).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Env�a cada elemento de la lista al pid 
 % proporcionado. Cuando no quedan m�s 
 % elementos se env�a el �tomo end en una 
 % tupla y se finaliza.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
enviarElementosDeLista(Pid, []) ->
	Pid ! {'end'};
enviarElementosDeLista(Pid, [Cabeza|Resto]) ->
	Pid ! Cabeza,
	enviarElementosDeLista(Pid, Resto). % Llamada recursiva.










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLOS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % A continuaci�n tenemos una serie de ejemplos, de los que se disponen las funciones datos, map y 
 % reduce seguido del n�mero de ejemplo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLOS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLO1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Ejemplo proporcionado en la descripci�n de la pr�ctica. Dada una lista de tuplas con ciudades y 
 % temperaturas, filtra las que no superan los 28 grados de m�xima y selecciona de esas la que tenga
 % mayor temperatura m�xima en cada ciudad.
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
 % Funci�n map del ejemplo 1.
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
 % Funci�n reduce del ejemplo 1.
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
 % Ejemplo extra requerido en la entrega de la pr�ctica. Dada una lista de palabras (pertenecientes 
 % a una frase) selecciona todas ellas y cuenta las apariciones de cada una.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EJEMPLO2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Datos del ejemplo 2.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
datos2() ->
	[
		la,
		jarra,
		est�,
		encima,
		de,
		la,
		mesa
	].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funci�n map del ejemplo 2.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
map2() ->
	fun(Palabra)->
		{Palabra, 1}
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Funci�n reduce del ejemplo 2.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reduce2() ->
	fun(Clave, ValorAntiguo, _ValorNuevo) ->
		{Clave, ValorAntiguo + 1}
	end.




