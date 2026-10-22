-- OSM Overpass FCT park/terminal candidates for Abuja (ODbL 1.0).
-- Generated 2026-09-21. Excludes duplicates of seed_abuja_pilot field_verified parks.
-- verification_status=candidate — field-verify before trusting for matching.
-- Requires seed_abuja_pilot (Abuja city).
-- Attribution: © OpenStreetMap contributors — https://www.openstreetmap.org/copyright

insert into data_sources (id, source_type, notes) values
  ('c1300000-0000-4000-8000-000000000001', 'import', 'OpenStreetMap Overpass FCT parks/terminals export 2026-09-21 (ODbL)')
on conflict (id) do nothing;

insert into parks (id, city_id, name, name_aliases, location, source_id, verification_status, confidence_score, active)
values
  ('5a643a18-037e-57fa-b171-995dbe5704d6', 'b1000000-0000-4000-8000-000000000001', 'God is Good', array['osm:node/5986883885'], st_setsrid(st_makepoint(7.438076, 9.065495), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('b5490eb1-2233-5454-94a9-6fd0460f9c93', 'b1000000-0000-4000-8000-000000000001', 'Mabushi Bus Terminal', array['osm:node/13383633683'], st_setsrid(st_makepoint(7.456514, 9.086570), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('b8867291-0330-523a-bbaa-d99497d2c79f', 'b1000000-0000-4000-8000-000000000001', 'Nyanya bus station', array['osm:node/5234383123'], st_setsrid(st_makepoint(7.570635, 9.023419), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('a64572a1-cfbe-5292-bee2-7debddd0eea3', 'b1000000-0000-4000-8000-000000000001', 'Zuba', array['osm:node/4465077889'], st_setsrid(st_makepoint(7.215967, 9.093237), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('90843d89-f1c0-59d8-8db6-55fb6b409529', 'b1000000-0000-4000-8000-000000000001', 'Area 10 Bus Stop', array['osm:node/14024364207'], st_setsrid(st_makepoint(7.485750, 9.039280), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('795c334b-513b-578f-a239-7f01ae458975', 'b1000000-0000-4000-8000-000000000001', 'Area 3 Junction', array['osm:node/14024364171'], st_setsrid(st_makepoint(7.475547, 9.025247), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('8140c892-4875-52c0-a296-7a52458b70b1', 'b1000000-0000-4000-8000-000000000001', 'Area 8 Bus Station', array['osm:node/14024364192'], st_setsrid(st_makepoint(7.487923, 9.034884), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('9db2644f-4c78-55c0-a7f5-5c1891e12379', 'b1000000-0000-4000-8000-000000000001', 'El-Rufai Bus Station', array['osm:node/14024364180'], st_setsrid(st_makepoint(7.324686, 9.147636), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('d1bc5031-3761-552d-ae41-5704654b834f', 'b1000000-0000-4000-8000-000000000001', 'G.U.O Transport - Zuba(Fct) Terminal', array['osm:node/14024364161'], st_setsrid(st_makepoint(7.214963, 9.090515), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('03cf707e-08c8-5e3b-bfdd-b042e083aa45', 'b1000000-0000-4000-8000-000000000001', 'Gwarinpa Bus Stop', array['osm:node/14024364217'], st_setsrid(st_makepoint(7.405881, 9.119152), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('742d8a4d-ca8f-5e12-b636-6523336132b3', 'b1000000-0000-4000-8000-000000000001', 'Jabi Central Bus Station', array['osm:node/14024364118'], st_setsrid(st_makepoint(7.434417, 9.064870), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('fd2b970d-b777-5b35-a701-5494818a3bd0', 'b1000000-0000-4000-8000-000000000001', 'Jabi Motor Park', array['osm:node/14024364181'], st_setsrid(st_makepoint(7.432691, 9.063830), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('b4213ed3-c1f8-50d3-b1c1-d122e130004c', 'b1000000-0000-4000-8000-000000000001', 'Kuje', array['osm:node/14024356443'], st_setsrid(st_makepoint(7.186059, 8.894084), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('6edb0b00-044d-51b7-b9fd-fea9de8d0a0b', 'b1000000-0000-4000-8000-000000000001', 'Life Camp Bus Station', array['osm:node/14024364186'], st_setsrid(st_makepoint(7.402902, 9.068010), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('0e532124-631b-57c9-9046-3dd2c1c46543', 'b1000000-0000-4000-8000-000000000001', 'Lugbe Bus Stop', array['osm:node/14024356419'], st_setsrid(st_makepoint(7.379995, 8.980837), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('2b4c94aa-2cce-5040-8e02-737ad9bbae1b', 'b1000000-0000-4000-8000-000000000001', 'Lugbe By Car Wash Bridge', array['osm:node/14024364126'], st_setsrid(st_makepoint(7.381337, 8.964179), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('959c1611-c2ec-5481-b200-805a129387e8', 'b1000000-0000-4000-8000-000000000001', 'Nnpc Bus Station', array['osm:node/14024364201'], st_setsrid(st_makepoint(7.485884, 9.056011), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('b806d954-bc9c-59c6-9fe2-418ec0c8a1c3', 'b1000000-0000-4000-8000-000000000001', 'Wuse Bus Station', array['osm:node/14024364183'], st_setsrid(st_makepoint(7.464929, 9.066050), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true),
  ('5d89b919-08d1-5755-ad21-fd84371d6b3c', 'b1000000-0000-4000-8000-000000000001', 'Wuse District Hospital Bus Stop', array['osm:node/14024364174'], st_setsrid(st_makepoint(7.468070, 9.062920), 4326)::geography, 'c1300000-0000-4000-8000-000000000001', 'candidate', 0.550, true)
on conflict (id) do update set
  name = excluded.name,
  name_aliases = excluded.name_aliases,
  location = excluded.location,
  updated_at = now();
