/*
Miguel Benayas Penas 
Creación de una Base de Datos (Marzo 2021)

Indice:

1. Crear Base de Datos
2. Borrar instancias pasadas de las tablas 
3. Crear Tablas
4. Insertar valores tablas 
5. Creación del disparador para la tabla es_familia
6. Consultas (18)
*/

/* *****************************************************
	1. Crear Base de Datos
   *****************************************************
*/

drop database if exists espana_relimpia;
create database espana_relimpia;
use espana_relimpia;

/* *****************************************************
	2. Borrar instancias pasadas de tablas, vistas ... 
    (solo necesario durante la fase desarrollo)
   *****************************************************
*/
drop table if exists juez;
drop table if exists partidopolitico;
drop table if exists telefono_partido;
drop table if exists implicado;
drop table if exists periodico;
drop table if exists caso;
drop table if exists ambito_caso;
drop table if exists involucra;
drop table if exists es_familia;

-- Borrar vistas
drop view if exists vista_partido_casos_asociados;
drop view if exists jueces_periodicos;

-- Borrar disparadores
drop trigger if exists maxCasosPorJuez ;
drop trigger if exists noBA ;
/* *****************************************************
	3. Crear Tablas
   *****************************************************
*/
create table juez(
codigo smallint,-- no se esperan tantos jueces como para hacerlo int
nombre varchar(50) not null,-- siguiendo ejemplos de clase, como para direcciones o apellidos
apellido1 varchar(50) not null,
apellido2 varchar(50) not null,
fecNac date,
fecEjercer date not null,
direccion varchar(100) not null,
primary key (codigo)
);

create table partidopolitico(
nombre varchar(50),
direccion varchar(100) not null unique,
primary key(nombre)
);


create table telefono_partido(
numero char(9),
partido varchar(50),
primary key (numero),
foreign key(partido) references partidopolitico(nombre)
on delete cascade -- borro partido, borro su telefono
on update cascade -- actualizo el nombre del partido si se cambia
);

create table periodico(
nombre varchar(50),
tirada varchar(7) not null, -- papel o digital
web varchar(50) not null, 
ambito varchar(13) not null,-- maximos caracteres: internacional (13)
direccion varchar(100) not null unique,
partido varchar(50),
primary key(nombre),
foreign key(partido) references partidopolitico(nombre)
on delete restrict -- si borro partido, no borro periodico
on update cascade);-- actualizo nombre partido

alter table periodico -- tirada solo puede adpotar dos valores
add constraint tirada check (tirada= 'papel' or tirada ='digital');


create table caso (
nombre varchar(50),
descripcion varchar(100) unique,
millones numeric(15,2) not null, -- orden de un billon hispano euros (2 decimales)
codjuez smallint,
dictamen char(4), -- codigo dictamen del juez para el caso
nombre_periodico varchar(50),
fecDesc date not null,
primary key (nombre),
foreign key (codjuez) references juez(codigo)
on delete restrict
on update cascade,
foreign key (nombre_periodico) references periodico(nombre)
on delete restrict
on update cascade
);
alter table caso -- millones debe ser una cantidad positiva 
add constraint millones check (millones >0);


create table ambito_caso( -- atributo multivalorado
tipo_ambito varchar(50), 
nombre_caso varchar(50),
primary key (tipo_ambito,nombre_caso),
foreign key (nombre_caso) references caso(nombre)
on delete cascade
on update cascade);

create table implicado(
dni char(9),
nombre char(50) not null,
apellido1 char(50) not null,
apellido2 char(50) not null,
direccion varchar(100),
patrimonio numeric(15,2),
partido varchar(50),
vinculo_partido varchar(50),
primary key (dni),
foreign key(partido) references partidopolitico(nombre)
on delete restrict -- si borro partido, no borro implicados
on update cascade-- actualizo nombre partido
);

--  crear relaciones N:N

create table involucra(
nombre_caso varchar(50),
dni char(9),
rol varchar(50) not null,
dinero numeric(9,2) not null, -- millones de euros
primary key (nombre_caso, dni),
foreign key (nombre_caso) references caso(nombre)
on delete cascade -- para involucrar a alguien debe existir
on update cascade
,
foreign key (dni) references implicado(dni)
on delete cascade
on update cascade
);

create table es_familia(
dni_implicado_1 char(9),
dni_implicado_2 char(9),
relacion_1_con_2 varchar(50),
primary key (dni_implicado_1, dni_implicado_2),
foreign key (dni_implicado_1) references implicado(dni)
on delete cascade
on update cascade,
foreign key (dni_implicado_2) references implicado(dni)
on delete cascade
on update cascade
);

/* *****************************************************
	4. Insertar valores tablas (mismo orden que definicion)
   *****************************************************
*/

SELECT @@GLOBAL.secure_file_priv;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/juez.csv'
IGNORE INTO TABLE juez -- ignorar errores al insertar en la tabla 'juez'
CHARACTER SET latin1
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\n'
IGNORE 1 rows; -- ignoramos la línea con los nombres de las columnas     

insert into partidopolitico values
('Azul', 'Avenida La Paz 11, 28005, Madrid'),
('Rojo','Calle Pinto 54, 48005, Barcelona'),
('Verde','Calle Coimbra 54, 27009, Madrid'),
('Amarillo','Calle Laurel 34, 41007, Lugo');


insert into telefono_partido values
('918765499','Azul'),
('918947625','Azul'),
('956694625','Rojo'),
('939875462','Verde'),
('939995462','Verde'),
('975684321','Amarillo');

insert into periodico values
('Vanguardia','digital','www.vanguardia.com','internacional','Via 1 28807, Madrid','Amarillo'),
('El Pais','papel','www.elpais.es','nacional','Avenia 12 29807, Teruel','Verde'),
('El Mundo','digital','www.elmundo.es','nacional','Via Constitución 28307, Zaragoza',null),
('La Razon','papel','www.larazon.com','internacional','Calle Gernika 25807, Bibao','Rojo'),
('Diario Publico','digital','www.diariopublico.es','nacional','Via 21 28807, Madrid','Verde');


insert into caso values 

('Gurtel','Descripcion Gurtel',1000,001,'0001','Vanguardia','2007-08-24'),
('ERES','Descripcion ERES',400.25,001,'0002','Vanguardia','2008-11-14'),
('Punica Malaya','Descripcion Punica Malaya',3000,003,'0003','El Pais','2009-10-23'),
('Tarjetas Black','Descripcion Tarjetas Black',768,002,'0004','El Mundo','2010-09-14'),
('Puyol','Descripcion Puyol',20000,004,'0005','La Razon','2014-01-19'),
('Palau','Descripcion Palau',12567.1,005,'0006','Diario Publico','2011-03-30');

insert into ambito_caso values
('Banco','Gurtel'),
('Comunidad','Gurtel'),
('Comunidad','ERES'),
('Caja','ERES'),
('Estado','ERES'),
('Comunidad','Punica Malaya'),
('Estado','Tarjetas Black'),
('Caja','Puyol'),
('Estado','Puyol'),
('Ayuntamiento','Palau');

insert into implicado values
('51183401C','Juan','Molina','Perez','Madrid',34,'Azul','afiliado'),
('91183101S','Ramon','Martinez','Otero','Barcelona',12,null,null),
('81684401T','Julia','Rodriguez','Velez','Madrid',24,'Rojo','afiliado'),
('71783331W','Beatriz','Simon','Alegre','Valencia',500,'Rojo','militante'),
('51383601A','Carmen','Ferrero','Busquets','Madrid',250,'Verde','afiliado'),
('61183401X','Gorka','Aguirre','Liceaga','Barcelona',5000,'Amarillo','militante'),
('41783001R','Isabel','Martinez','Heredia','Vigo',630,null,null);

insert into involucra values
('Gurtel','51183401C','jefe',20),
('ERES','51183401C','colabora',5),
('Punica Malaya','51183401C','colabora',7.5),
('Tarjetas Black','91183101S','colabora',13),
('Puyol','81684401T','jefe',30),
('Gurtel','71783331W','colabora',2.45),
('ERES','51383601A','jefe',4.6),
('Tarjetas Black','61183401X','jefe',6),
('Punica Malaya','71783331W','jefe',50),
('Gurtel','51383601A','colabora',13),
('Palau','51383601A','colabora',10);

insert into es_familia values
('51183401C','91183101S','pariente_cercano'),
('81684401T','51383601A','pariente_cercano');

/* *****************************************************
	5. Creación del disparador para la tabla es_familia
   *****************************************************
*/

DELIMITER $$
create trigger noBA
before insert on es_familia
for each row
begin
	if exists	(select dni_implicado_1 as A, dni_implicado_2 as B
				 from es_familia
                 where dni_implicado_1=new.dni_implicado_2 and dni_implicado_2=new.dni_implicado_1)
	then
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'Este parentesco ya ha sido registrado a la inversa', MYSQL_ERRNO = 1001;
   END IF;
END$$
DELIMITER ;

insert into es_familia values
('71783331W','51183401C','pariente_lejano');

/*
 -- Comprobación del disparador
 -- Activando esta sentencia se ve que el disparador definido anteriormente funciona para evitar 
 -- información redundante en es_familia.
 
insert into es_familia values
('91183101S','51183401C','pariente_cercano');
*/


/* *****************************************************
	6. Consultas (17)
   *****************************************************
*/


-- 1) Nombre de los periódicos independientes, sin afinidad a ningún partido
select nombre 
from periodico 
where partido is null;


-- 2) Ciudad con el máximo numero de corruptos
select direccion as ciudad_con_mas_corruptos, count(*) as numero_corruptos
from implicado
group by ciudad_con_mas_corruptos
order by numero_corruptos desc
limit 1; -- pide ciudad, no ciudades. Me centro en la del valor máximo

-- 3) Total dinero defraudado por partido si y solo si la persona esta afiliada
-- Un implicado de un partido puede participar en X casos, toda la cantidad
-- de esos X casos será agregada al dinerto total defraudada por partido
select implicado.partido as partido_politico, sum(involucra.dinero) as dinero_defraudado
from implicado, involucra
where implicado.dni=involucra.dni and implicado.partido is not null
group by partido_politico
order by dinero_defraudado desc
;

-- 4) Periódico que más casos ha descubierto
select nombre_periodico as periodico, count(*) as numero_casos
from caso
group by periodico
order by numero_casos desc
limit 1;


-- 5) Número de familiares de 51183401C con casos de corrupcion
select count(*) as numero_familiares
from es_familia
where dni_implicado_1='51183401C' or  dni_implicado_2='51183401C';


-- 6) Partidos políticos con sede en Madrid
select nombre as partido, direccion
from partidopolitico
where direccion like '%Madrid%';-- contenga subcadena Madrid

-- 7) Jueces investigando casos con cuantías mayores de 900 millones de euros
select j.codigo as codigo_juez, c.nombre as nombre_caso, c.millones as cuantia_caso
from juez as j inner join caso as c on j.codigo=c.codjuez
where c.millones>900; 

--  8) Implicados que son parientes cercanos de otro implicado
select i.dni, f.relacion_1_con_2 as tiene_implicado_a
from implicado as i right join es_familia as f on (i.dni=f.dni_implicado_1 or i.dni=f.dni_implicado_2)
where f.relacion_1_con_2='pariente_cercano';


-- 9) Partiodos políticos con más de un implicado
select partido, count(*) as numero_implicados
from implicado
where partido is not null
group by partido
having numero_implicados>1;


-- 10) Nombre y apellidos de implicados y jueces que tengan como nombre de pila 'Juan'

(SELECT nombre, apellido1,apellido2 FROM implicado where nombre = 'Juan')
union
(SELECT nombre, apellido1,apellido2 FROM juez where nombre = 'Juan');

-- 11) Partidos con implicados que no tienen ningún familiar implicado
select p.nombre as nombre_partido, i.dni as dni_sin_familiar
from partidopolitico as p inner join implicado as i on p.nombre=i.partido
where i.dni not in (select dni_implicado_1 from es_familia)
	  and i.dni not in (select dni_implicado_2 from es_familia); 

-- 12) Todos los casos con al menos un implicado como colaborador
select distinct(nombre_caso)
from involucra
where  rol='colabora';

-- 13) Jueces que nacieron entre 1950 y 1970
select codigo,fecNac
from juez
where fecNac between '1950-01-01' and '1970-01-01';

-- 14) Suma un millon al dinero defraudado  de un caso si su ambito tiene como valor al menos 'Estado'
select c.nombre as nombre_caso, c.millones as millones_antes, c.millones +1 as millones_mas_1
from caso as c inner join ambito_caso as a on c.nombre=a.nombre_caso
where a.tipo_ambito ='Estado'; 

-- 15) Actualizar un numero de telefono de un partido politico
update telefono_partido
set numero= '999965499' 
WHERE numero='918765499';
select * from telefono_partido;


-- 16) Generar una vista con nombre de partido y su dirección junto
--     con el nombre de los caso(s) de corrupción del que algún militante suyo esté involucrado
create view vista_partido_casos_asociados as
select p.nombre as nombre_partido, p.direccion as direccion, inv.nombre_caso as caso
from partidopolitico as p,involucra as inv,implicado as imp
where imp.partido=p.nombre and inv.dni=imp.dni and imp.vinculo_partido='militante';

select * from vista_partido_casos_asociados;


-- 17) Generar una vista de los nombres de pila de los jueces y nombre de los periódicos de 
-- ámbito 'internacional', sin duplicados
create view jueces_periodicos as
select distinct(j.nombre) as nombre_pila_juez, p.nombre as nombre_periodico
from juez as j, periodico as p
where p.ambito='internacional';

select * from jueces_periodicos;

/*
*/

-- 18) Crear un trigger para impedir que un juez pueda llevar más de dos casos
DELIMITER $$

CREATE TRIGGER maxCasosPorJuez
before update ON caso
FOR EACH ROW
BEGIN
	if exists (select codjuez, count(*)  from caso group by codjuez
	having count(*)=2 and codjuez=new.codjuez) 
	then 
    
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'Este juez ya tiene dos casos', MYSQL_ERRNO = 1001;
   -- update caso
   -- set new.codjuez = old.codjuez;
   END IF;
END$$
DELIMITER ;

select * from caso;

update caso
set codjuez = 003
WHERE nombre='Puyol';

select * from caso;
/*
-- El dispador creado, como se espera, hace saltar el error definido
update caso
set codjuez = 001
WHERE nombre='Puyol';
*/


