CREATE DATABASE banque;
use banque;
CREATE TABLE clients (
    id int auto_increment PRIMARY KEY,
    nom VARCHAR(100)
);

CREATE TABLE comptes (
    id int auto_increment PRIMARY KEY,
    client_id INT REFERENCES clients(id),
    type VARCHAR(50)
);

CREATE TABLE transactions (
    id int auto_increment PRIMARY KEY,
    compte_id INT REFERENCES comptes(id),
    type VARCHAR(50),
    montant DECIMAL(12,2),
    date DATE
);


delimiter $$
CREATE FUNCTION fn_solde_compte(compte_id INT)
RETURNS DECIMAL 
DETERMINISTIC
BEGIN
DECLARE solde DECIMAL(12,2);
    SELECT
        COALESCE(SUM(
            CASE
                WHEN type = 'depot' THEN montant
                WHEN type = 'retrait' THEN -montant
                ELSE 0
            END
        ),0)
    INTO solde
    FROM transactions
    WHERE transactions.compte_id = fn_solde_compte.compte_id;
    RETURN solde;
END $$ 
delimiter $$;

CREATE VIEW vue_solde_moyen_client AS
(SELECT c.id, c.nom,
AVG(fn_solde_compte(cp.id)) AS solde_moyen
FROM clients c
JOIN comptes cp ON c.id = cp.client_id
GROUP BY c.id, c.nom);


CREATE VIEW vue_top10_clients_transactions AS
(SELECT c.id, c.nom,
COUNT(t.id) AS nb_transactions
FROM clients c
JOIN comptes cp ON c.id = cp.client_id
JOIN transactions t ON cp.id = t.compte_id
GROUP BY c.id, c.nom
ORDER BY nb_transactions DESC
LIMIT 10);


CREATE VIEW vue_transaction_max_mois AS
(SELECT *
FROM transactions
WHERE montant = (
    SELECT MAX(montant)
    FROM transactions
    WHERE DATE_format('month', date) = DATE_format('month', CURRENT_DATE)
));

CREATE VIEW vue_nb_transactions_type AS
(SELECT type,
COUNT(*) AS nombre_transactions
FROM transactions
GROUP BY type);


CREATE VIEW vue_moyenne_transactions_client AS
(SELECT c.id, c.nom,
AVG(t.montant) AS moyenne_transactions
FROM clients c
JOIN comptes cp ON c.id = cp.client_id
JOIN transactions t ON cp.id = t.compte_id
GROUP BY c.id, c.nom);

CREATE VIEW vue_moyenne_retraits_client AS
(SELECT c.id, c.nom,
AVG(t.montant) AS moyenne_retraits
FROM clients c
JOIN comptes cp ON c.id = cp.client_id
JOIN transactions t ON cp.id = t.compte_id
WHERE t.type = 'retrait'
GROUP BY c.id, c.nom);


CREATE VIEW vue_solde_total_annee AS
(SELECT EXTRACT(YEAR FROM date) AS annee,
SUM(
    CASE
        WHEN type = 'depot' THEN montant
        WHEN type = 'retrait' THEN -montant
        ELSE 0
    END
) AS solde_total
FROM transactions
GROUP BY annee);


CREATE VIEW vue_client_plus_transactions AS
(SELECT c.id, c.nom,
COUNT(t.id) AS nb_transactions
FROM clients c
JOIN comptes cp ON c.id = cp.client_id
JOIN transactions t ON cp.id = t.compte_id
GROUP BY c.id, c.nom
ORDER BY nb_transactions DESC
LIMIT 1);


CREATE VIEW vue_nb_comptes_client AS
(SELECT c.id, c.nom,
COUNT(cp.id) AS nombre_comptes
FROM clients c
LEFT JOIN comptes cp ON c.id = cp.client_id
GROUP BY c.id, c.nom);


CREATE VIEW vue_moyenne_transactions_mois AS
(SELECT EXTRACT(MONTH FROM date) AS mois,
AVG(montant) AS moyenne_transactions
FROM transactions
GROUP BY mois);


CREATE VIEW vue_client_solde_max AS
(SELECT c.id, c.nom,
SUM(
    CASE
        WHEN t.type = 'depot' THEN t.montant
        WHEN t.type = 'retrait' THEN -t.montant
        ELSE 0
    END
) AS solde
FROM clients c
JOIN comptes cp ON c.id = cp.client_id
JOIN transactions t ON cp.id = t.compte_id
GROUP BY c.id, c.nom
ORDER BY solde DESC
LIMIT 1);


CREATE VIEW vue_transactions_annulees AS
(SELECT COUNT(*) AS nb_transactions_annulees
FROM transactions
WHERE type = 'annulee');


CREATE VIEW vue_ca_total_banque AS
(SELECT SUM(montant) AS chiffre_affaires
FROM transactions
WHERE type = 'depot');


CREATE VIEW vue_distribution_transactions AS
(SELECT type,
COUNT(*) AS total,
ROUND(
    COUNT(*) * 100.0 /
    (SELECT COUNT(*) FROM transactions), 2
) AS pourcentage
FROM transactions
GROUP BY type);

CREATE VIEW vue_croissance_depots_annee AS
(SELECT
EXTRACT(YEAR FROM date) AS annee,
SUM(montant) AS total_depots
FROM transactions
WHERE type = 'depot'
GROUP BY annee
ORDER BY annee);

INSERT INTO clients (nom) VALUES
('Jean'),
('Marie'),
('Paul'),
('Sophie'),
('David'),
('Clarisse'),
('Kevin'),
('Brenda'),
('Patrick'),
('Laura');



INSERT INTO comptes (client_id, type) VALUES
(1, 'courant'),
(1, 'epargne'),
(2, 'courant'),
(3, 'epargne'),
(4, 'courant'),
(5, 'courant'),
(6, 'epargne'),
(7, 'courant'),
(8, 'epargne'),
(9, 'courant'),
(10, 'courant');



INSERT INTO transactions (compte_id, type, montant, date) VALUES
(1, 'depot', 500000, '2025-01-10'),
(1, 'retrait', 100000, '2025-01-12'),
(2, 'depot', 250000, '2025-02-05'),
(3, 'depot', 700000, '2025-02-15'),
(3, 'retrait', 150000, '2025-02-18'),
(4, 'depot', 300000, '2025-03-01'),
(4, 'retrait', 50000, '2025-03-02'),
(5, 'depot', 1000000, '2025-03-10'),
(5, 'retrait', 200000, '2025-03-12'),
(6, 'depot', 450000, '2025-04-01'),
(6, 'annulee', 100000, '2025-04-02'),
(7, 'depot', 600000, '2025-04-05'),
(8, 'retrait', 120000, '2025-04-07'),
(8, 'depot', 350000, '2025-04-08'),
(9, 'depot', 800000, '2025-05-01'),
(9, 'retrait', 100000, '2025-05-03'),
(10, 'depot', 950000, '2025-05-10'),
(10, 'retrait', 300000, '2025-05-12'),
(11, 'depot', 400000, '2025-05-15'),
(11, 'annulee', 50000, '2025-05-16');