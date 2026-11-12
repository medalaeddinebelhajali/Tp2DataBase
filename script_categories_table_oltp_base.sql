DROP TABLE IF EXISTS public.categories;

CREATE TABLE public.categories (
    id_categorie   INT PRIMARY KEY,
    code_categorie VARCHAR(20) NOT NULL UNIQUE,
    nom_categorie  VARCHAR(100) NOT NULL
);

INSERT INTO public.categories (id_categorie, code_categorie, nom_categorie) VALUES
(10, 'ELEC', 'Électronique'),
(20, 'INFO', 'Informatique'),
(30, 'MOBI', 'Mobilier de bureau'),
(40, 'FOUR', 'Fournitures');