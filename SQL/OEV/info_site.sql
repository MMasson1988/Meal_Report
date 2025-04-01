use caris_db;

SELECT concat(city_code,"/",hospital_code)as Site, lh.name as Hospital, ld.name as Departement, lc.name as Commune, ln.name as network FROM caris_db.lookup_hospital lh
left join lookup_commune lc  on lc.id=lh.commune
left join lookup_departement ld on ld.id=lh.departement
left join lookup_network ln on ln.id=lh.network