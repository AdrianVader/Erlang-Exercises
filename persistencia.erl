% coding: latin-1

-module(persistencia).
% -export([leeFichero/1, parseaFichero/1, construyeTablaETS/1]).
-compile(export_all).

% En la consola de Windows, para cambiar de disco duro "d:".
% cd("d:universidad/2Master/PDA/Practicas").
% c(persistencia).
% Probar con:
% P = persistencia:parseaFichero("clientes.txt").
% persistencia:construyeTablaETS(P).
% ets:lookup(tabla, 1).



leeFichero (NombreFichero) -> % "clientes2.txt"
	{ok, F} = file:open(NombreFichero, [read]), 
	{ok, L} = io:read(F, ""), 
	file:close(F), 
	L.

parseaFichero (NombreFichero) -> % "clientes.txt"
	{ok, F} = file:open(NombreFichero, [read]), 
	
	ListaPersonas = parseaPersonas (F), 
	
	file:close(F), 
	ListaPersonas.

parseaPersona (F) ->
	L = io:get_line(F, ""), 
	case L of
		eof ->
			[];
		_ -> 
			ListaTokens = string:tokens(L, ",\n"), 
			[Numero, Nombre, Edad, Ciudad] = ListaTokens, 
			ListaStrip = [string:strip(Numero), string:strip(Nombre), string:strip(Edad), string:strip(string:strip(Ciudad), both, $.)], 
			[NumeroStrip, NombreStrip, EdadStrip, CiudadStrip] = ListaStrip, 
			{NumeroInt, _Resto1} = string:to_integer(NumeroStrip), 
			{EdadInt, _Resto2} = string:to_integer(EdadStrip), 
			Persona = {NumeroInt, NombreStrip, EdadInt, CiudadStrip}, 
			Persona
	end.

parseaPersonas (F) -> 
	Persona = parseaPersona (F), 
	case Persona of
		[] -> 
			[];
		_ -> 
			[Persona | parseaPersonas (F)]
	end.
	
	
construyeTablaETS (Personas) ->
	ets:new(tabla, [set, public, named_table, {keypos, 1}]), 
	insertaPersonas (Personas), 
	Personas.

insertaPersonas (Personas) -> 
	ets:insert(tabla, Personas).
	
	
% 3)
% Ciudad de residencia del usuario con identi1cador 3.
% 	ets:match(tabla, {3, '_', '_', '$1'}).

% Nombres y apellidos de los residentes en Madrid cuyo nombre comience por C.
%	ets:select(tabla, [{{'_', ['$1'|'$2'], '_', "Madrid"}, [{'==', hd("C"), '$1'}], [['$1'|'$2']]}]).

% Nombres y apellidos de los usuarios que tengan entre 20 y 30 años (inclusive).
% 	ets:select(tabla, [{{'_', '$1', '$2', '_'}, [{'>=', '$2', 20}, {'=<', '$2', 30}], ['$1']}]).


