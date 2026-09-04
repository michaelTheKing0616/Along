-- doc 02 §14 / §16: ops select/update reconciliations in city scope (writes via RPC).
create policy field_reconciliations_select_admin
  on field_reconciliations for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((
      select fs.city_id from field_submissions fs where fs.id = submission_a
    ))
  );

create policy field_reconciliations_update_admin
  on field_reconciliations for update to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((
      select fs.city_id from field_submissions fs where fs.id = submission_a
    ))
  )
  with check (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((
      select fs.city_id from field_submissions fs where fs.id = submission_a
    ))
  );
