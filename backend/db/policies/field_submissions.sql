-- doc 02 §14 / §16: scouts insert/select own; ops select/update in city scope.
create policy field_submissions_insert_agent
  on field_submissions for insert to authenticated
  with check (
    scout_profile_id = auth.uid()
    and exists (
      select 1 from field_agents fa
      where fa.id = auth.uid() and fa.city_id = field_submissions.city_id and fa.active
    )
  );

create policy field_submissions_select_agent
  on field_submissions for select to authenticated
  using (scout_profile_id = auth.uid());

create policy field_submissions_select_admin
  on field_submissions for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));

create policy field_submissions_update_admin
  on field_submissions for update to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));
