DROP SCHEMA IF EXISTS film_database;
CREATE SCHEMA film_database;
USE film_database;

CREATE TABLE users(
	user_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    age INT NOT NULL,
    email VARCHAR(100) NOT NULL
);

CREATE TABLE lists(
	list_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    user_id INT NOT NULL, FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE directors(
	director_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE actors(
	actor_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE genres(
	genre_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE countries(
	country_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE films(
	film_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    year INT NOT NULL,
    director_id INT NOT NULL, FOREIGN KEY (director_id)
    REFERENCES directors(director_id),
    actor_id INT NOT NULL, FOREIGN KEY (actor_id)
    REFERENCES actors(actor_id),
    genre_id INT NOT NULL, FOREIGN KEY (genre_id)
    REFERENCES genres(genre_id),
    country_id INT NOT NULL, FOREIGN KEY (country_id)
    REFERENCES countries(country_id)
);

CREATE TABLE film_acting(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    actor_id INT NOT NULL, FOREIGN KEY (actor_id)
    REFERENCES actors(actor_id),
    film_id INT NOT NULL, FOREIGN KEY (film_id)
    REFERENCES films(film_id)
);

CREATE TABLE film_genre(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    genre_id INT NOT NULL, FOREIGN KEY (genre_id)
    REFERENCES genres(genre_id),
    film_id INT NOT NULL, FOREIGN KEY (film_id)
    REFERENCES films(film_id)
);

CREATE TABLE film_origin(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    country_id INT NOT NULL, FOREIGN KEY (country_id)
    REFERENCES countries(country_id),
    film_id INT NOT NULL, FOREIGN KEY (film_id)
    REFERENCES films(film_id)
);

CREATE TABLE film_list(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    list_id INT NOT NULL, FOREIGN KEY (list_id) REFERENCES lists(list_id),
    film_id INT NOT NULL, FOREIGN KEY (film_id) REFERENCES films(film_id)
);

CREATE TABLE played_lists(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    list_id INT NOT NULL, FOREIGN KEY (list_id) REFERENCES lists(list_id),
    user_id INT NOT NULL, FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE shared_lists(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    list_id INT NOT NULL, FOREIGN KEY (list_id) REFERENCES lists(list_id),
    user_id INT NOT NULL, FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO directors VALUES
(NULL, 'Chantal Akerman'),
(NULL, 'Alfred Hitchcock'),
(NULL, 'Orson Welles'),
(NULL, 'Ozu Yasujiro'),
(NULL, 'Wong Kar Wai');

INSERT INTO actors VALUES
(NULL, 'Delphine Seyrig'),
(NULL, 'James Stewart'),
(NULL, 'Orson Welles'),
(NULL, 'Setsuko Hara'),
(NULL, 'Maggie Cheung'),
(NULL, 'Cary Grant');

INSERT INTO genres VALUES
(NULL, 'Drama'),
(NULL, 'Thriller'),
(NULL, 'Romance');

INSERT INTO countries VALUES
(NULL, 'Belgium'),
(NULL, 'USA'),
(NULL, 'Japan'),
(NULL, 'Hong Kong');

INSERT INTO films VALUES
(NULL, 'Jeanne Dielman, 23 quai du Commerce, 1080 Bruxelles', 1975, 1, 1, 1, 1),
(NULL, 'Vertigo', 1958, 2, 2, 2, 2),
(NULL, 'Citizen Kane', 1941, 3, 3, 1, 2),
(NULL, 'Tokyo Story', 1953, 4, 4, 1, 3),
(NULL, 'In the Mood for Love', 2000, 5, 5, 3, 4);

#Vistas

#Vista de la tabla films
CREATE OR REPLACE VIEW every_film AS
SELECT * FROM films;

#Vista de título de films y años únicamente
CREATE OR REPLACE VIEW each_film_and_year AS 
	(SELECT name, year from films);

#Vistas de películas con la palabra "love"
CREATE OR REPLACE VIEW love_films AS
(SELECT name, year FROM films
WHERE name like upper('%love%'));

#Vista de películas según décadas específicas
CREATE OR REPLACE VIEW film_by_decades AS
(SELECT name, year FROM films
WHERE year BETWEEN 1950 AND 1960);

#Vista de títulos de películas con nombre de director
CREATE OR REPLACE VIEW film_and_director AS
(SELECT f.name film_title, d.name director_name
FROM films f 
JOIN directors d
ON f.director_id = d.director_id);

#Vista de títulos de películas con nombre del primer actor/actriz
CREATE OR REPLACE VIEW films_and_actors AS
(SELECT f.name film_title, a.name actor_name
FROM films f 
JOIN actors a 
ON f.actor_id = a.actor_id);

#Vista de títulos de películas indicando género y país de origen
CREATE OR REPLACE VIEW film_genre_country AS
(SELECT f.name film_title, g.name film_genre, c.name film_origin 
FROM films f 
JOIN genres g 
ON f.genre_id = g.genre_id
JOIN countries c 
ON f.country_id = c.country_id);

# Función que recibe como parametro el id y retorna el titulo del film
DELIMITER $$
	CREATE FUNCTION `get_film_name` (id INT)
    RETURNS VARCHAR(100)
    DETERMINISTIC
    READS SQL DATA
    BEGIN
		RETURN (SELECT name FROM films WHERE film_id = id); 
    END
$$


# Función que recibe el id del film y mediante una subconsulta retorna el género
DELIMITER $$
	CREATE FUNCTION `get_film_genre` (id INT)
    RETURNS VARCHAR(100)
    DETERMINISTIC
    READS SQL DATA
    BEGIN
		RETURN (SELECT name FROM genres WHERE genre_id =
        (SELECT genre_id FROM films WHERE film_id = id));
    END
$$

# Stored Procedure que devuelve una columna ordenada y recibe como primer parámetro el campo
# y como segundo si es ascendente o descendente. Si se especifica con el parametro 'D' será descendente,
# sino por default será ascendente
DELIMITER $$
CREATE PROCEDURE `sp_get_films_order`(IN field CHAR(30), IN direction CHAR(1))
BEGIN
	IF field <> '' THEN
		SET @film_order = concat('ORDER BY ', field);
	ELSE
		SET @film_order = '';
	END IF;
    
    IF direction = 'D' THEN
		SET @order_direction = concat(' ', 'DESC');
	ELSE
		SET @order_direction = concat(' ', 'ASC');
	END IF;
    
    SET @clausula = concat('SELECT * FROM films ', @film_order, @order_direction);
	PREPARE runSQL FROM @clausula;
	EXECUTE runSQL;
	DEALLOCATE PREPARE runSQL;
END
$$

CALL sp_get_films_order('name', 'A');
CALL sp_get_films_order('year', 'D');

# Stored Procedure para agregar películas por parámetros, no permite incluir ningún
# id igual a 0 o un id de un actor, director, género o país que no existan
DELIMITER $$
CREATE PROCEDURE `sp_get_add_films`(IN name VARCHAR(200), IN year INT, IN dir_id INT, 
IN act_id INT, IN gen_id INT, IN count_id INT)
BEGIN
	START TRANSACTION;
	IF (dir_id = 0 OR act_id = 0 OR gen_id = 0 OR count_id = 0) THEN
		SET @err = 'dir_id, act_id, count_id or gen_id cannto be zero';
	SELECT @err;
    ELSE
		SET @err = '';
	IF NOT EXISTS(SELECT director_id from directors WHERE director_id = dir_id) THEN
			SET @err = CONCAT('director_id: ', dir_id, ' doesnt exist');
	END IF;
	IF NOT EXISTS(SELECT actor_id from actors WHERE actor_id = act_id) THEN
			SET @err = CONCAT('actor_id: ', act_id, ' doesnt exist');
	END IF;
	IF NOT EXISTS(SELECT genre_id from genres WHERE genre_id = gen_id) THEN
			SET @err = CONCAT('genre_id: ', gen_id, ' doesnt exist');
	END IF;
    IF NOT EXISTS(SELECT country_id from countries WHERE country_id = count_id) THEN
			SET @err = CONCAT('country_id: ', count_id, ' doesnt exist');
	END IF;
	IF @err != '' THEN
			SELECT @err;
		ELSE
	SET @film_data = concat("'", name, "','", year, "','",dir_id, "','",act_id, 
    "','",gen_id, "','",count_id, "')");
    SET @clausula = concat('INSERT INTO films VALUES(NULL,', @film_data);
	PREPARE runSQL FROM @clausula;
	EXECUTE runSQL;
	DEALLOCATE PREPARE runSQL;
    END IF;
    END IF;
    COMMIT;
END
$$

CALL sp_get_add_films('Enormous', 1995, 1, 1, 1, 1);

# Creación de tabla donde se replica los nuevos actores incluidos
# en la tabla `actors`
CREATE TABLE NEW_ACTORS (
	id_log INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	actor_id INT,
    name VARCHAR(200)
);

# Este trigger inserta en la tabla `new_actors` el id y el nombre
# del nuevo actor insertado en la tabla `actors`, después de la inserción
CREATE TRIGGER `tr_add_new_actor`
AFTER INSERT ON `actors`
FOR EACH ROW
INSERT INTO `NEW_ACTORS` (actor_id, name)
VALUES (NEW.actor_id, NEW.name);

INSERT INTO actors VALUES
(NULL, 'Anthony Perkins');

INSERT INTO actors VALUES
(NULL, 'Marlon Brando');

CREATE TABLE audits (
	id_log INT PRIMARY KEY AUTO_INCREMENT,
    entity varchar(100),
    entity_id int,
    insert_date date,
    insert_time time,
    last_updated_by varchar(100)
);

# Este trigger inserta en la tabla audits la información de fecha, hora y usuario
# cada vez que se realiza una modificación en la tabla `actors`
CREATE TRIGGER `tr_update_actor_aud`
BEFORE UPDATE ON `actors`
FOR EACH ROW
INSERT INTO `audits` (entity, entity_id, insert_date, insert_time, last_updated_by)
VALUES ('actor', NEW.actor_id, CURDATE(), CURTIME(), USER());

UPDATE actors SET name = 'James Dean' WHERE actor_id = 8;
UPDATE actors SET name = 'Spencer Tracy' WHERE actor_id = 6;

CREATE TABLE NEW_DIRECTORS (
	id_log INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	director_id INT,
    name VARCHAR(200)
);

# Este trigger inserta en la tabla `new_directors` el id y el nombre
# del nuevo director insertado en la tabla `director`, después de la inserción
CREATE TRIGGER `tr_add_new_director`
AFTER INSERT ON `directors`
FOR EACH ROW
INSERT INTO `NEW_DIRECTORS` (director_id, name)
VALUES (NEW.director_id, NEW.name);

INSERT INTO directors VALUES
(NULL, 'Otto Preminger');

INSERT INTO directors VALUES
(NULL, 'Billy Wilder');

# Este trigger inserta en la tabla audits la información de fecha, hora y usuario
# cada vez que se realiza una modificación en la tabla `directors`
CREATE TRIGGER `tr_update_director_aud`
BEFORE UPDATE ON `directors`
FOR EACH ROW
INSERT INTO `audits` (entity, entity_id, insert_date, insert_time, last_updated_by)
VALUES ('director', NEW.director_id, CURDATE(), CURTIME(), USER());

UPDATE directors SET name = 'John Huston' WHERE director_id = 3;
UPDATE directors SET name = 'Elia Kazan' WHERE director_id = 2;


