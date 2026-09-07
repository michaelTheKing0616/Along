-- pgTAP: P11-E-02 — doc 01 §7 list endpoints capped at max page 50
create extension if not exists pgtap;

begin;
select plan(2);

select ok(
  (
    select count(*)::int
    from places_search_graph(
      p_q := 'park',
      p_near_lat := 10.52,
      p_near_lng := 7.44,
      p_city_id := (select id from cities where slug = 'kaduna-pilot' limit 1),
      p_limit := 500,
      p_radius_m := 50000,
      p_min_similarity := 0.0
    )
  ) <= 50,
  'places_search_graph clamps p_limit to 50'
);

select is(
  (
    select count(*)::int
    from places_search_graph(
      p_q := 'park',
      p_near_lat := 10.52,
      p_near_lng := 7.44,
      p_city_id := (select id from cities where slug = 'kaduna-pilot' limit 1),
      p_limit := 3,
      p_radius_m := 50000,
      p_min_similarity := 0.0
    )
  ) <= 3,
  true,
  'places_search_graph honors requested limit below cap'
);

select * from finish();
rollback;
