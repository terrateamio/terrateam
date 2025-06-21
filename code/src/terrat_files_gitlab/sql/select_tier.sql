select tiers.id, tiers.name, tiers.features from tiers
inner join gitlab_installations as gis
   on gis.tier = tiers.id
where gis.id = $installation_id
