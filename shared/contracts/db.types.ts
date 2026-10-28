export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      admin_users: {
        Row: {
          city_scope: string[] | null
          corporate_account_id: string | null
          created_at: string
          deployment_id: string | null
          disabled_at: string | null
          id: string
          operator_account_id: string | null
          role: Database["public"]["Enums"]["admin_role"]
          updated_at: string
        }
        Insert: {
          city_scope?: string[] | null
          corporate_account_id?: string | null
          created_at?: string
          deployment_id?: string | null
          disabled_at?: string | null
          id: string
          operator_account_id?: string | null
          role: Database["public"]["Enums"]["admin_role"]
          updated_at?: string
        }
        Update: {
          city_scope?: string[] | null
          corporate_account_id?: string | null
          created_at?: string
          deployment_id?: string | null
          disabled_at?: string | null
          id?: string
          operator_account_id?: string | null
          role?: Database["public"]["Enums"]["admin_role"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_users_corporate_account_id_fkey"
            columns: ["corporate_account_id"]
            isOneToOne: false
            referencedRelation: "corporate_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_users_deployment_id_fkey"
            columns: ["deployment_id"]
            isOneToOne: false
            referencedRelation: "deployments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_users_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_users_operator_account_id_fkey"
            columns: ["operator_account_id"]
            isOneToOne: false
            referencedRelation: "operator_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      anonymized_od_cells: {
        Row: {
          city_id: string
          destination_geohash: string
          dow_bucket: number
          export_id: string
          hour_bucket: number
          id: string
          mode_code: string
          origin_geohash: string
          trip_count: number
        }
        Insert: {
          city_id: string
          destination_geohash: string
          dow_bucket: number
          export_id: string
          hour_bucket: number
          id?: string
          mode_code: string
          origin_geohash: string
          trip_count: number
        }
        Update: {
          city_id?: string
          destination_geohash?: string
          dow_bucket?: number
          export_id?: string
          hour_bucket?: number
          id?: string
          mode_code?: string
          origin_geohash?: string
          trip_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "anonymized_od_cells_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "anonymized_od_cells_export_id_fkey"
            columns: ["export_id"]
            isOneToOne: false
            referencedRelation: "anonymized_od_exports"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "anonymized_od_cells_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
        ]
      }
      anonymized_od_exports: {
        Row: {
          cells_emitted: number
          cells_suppressed: number
          city_id: string
          created_at: string
          geohash_precision: number
          id: string
          job_run_id: string
          k_threshold: number
          period_end: string
          period_start: string
          trips_examined: number
        }
        Insert: {
          cells_emitted?: number
          cells_suppressed?: number
          city_id: string
          created_at?: string
          geohash_precision: number
          id?: string
          job_run_id: string
          k_threshold: number
          period_end: string
          period_start: string
          trips_examined?: number
        }
        Update: {
          cells_emitted?: number
          cells_suppressed?: number
          city_id?: string
          created_at?: string
          geohash_precision?: number
          id?: string
          job_run_id?: string
          k_threshold?: number
          period_end?: string
          period_start?: string
          trips_examined?: number
        }
        Relationships: [
          {
            foreignKeyName: "anonymized_od_exports_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "anonymized_od_exports_job_run_id_fkey"
            columns: ["job_run_id"]
            isOneToOne: false
            referencedRelation: "job_runs"
            referencedColumns: ["id"]
          },
        ]
      }
      api_keys: {
        Row: {
          created_at: string
          id: string
          key_hash: string
          owner_organization: string
          rate_limit_per_min: number
          revoked_at: string | null
          scope: string[]
        }
        Insert: {
          created_at?: string
          id?: string
          key_hash: string
          owner_organization: string
          rate_limit_per_min: number
          revoked_at?: string | null
          scope: string[]
        }
        Update: {
          created_at?: string
          id?: string
          key_hash?: string
          owner_organization?: string
          rate_limit_per_min?: number
          revoked_at?: string | null
          scope?: string[]
        }
        Relationships: []
      }
      api_usage: {
        Row: {
          api_key_id: string
          calls: number
          day: string
        }
        Insert: {
          api_key_id: string
          calls?: number
          day: string
        }
        Update: {
          api_key_id?: string
          calls?: number
          day?: string
        }
        Relationships: [
          {
            foreignKeyName: "api_usage_api_key_id_fkey"
            columns: ["api_key_id"]
            isOneToOne: false
            referencedRelation: "api_keys"
            referencedColumns: ["id"]
          },
        ]
      }
      app_config: {
        Row: {
          description: string | null
          key: string
          scope_id: string
          scope_type: Database["public"]["Enums"]["config_scope"]
          updated_at: string
          updated_by: string | null
          value: Json
        }
        Insert: {
          description?: string | null
          key: string
          scope_id?: string
          scope_type?: Database["public"]["Enums"]["config_scope"]
          updated_at?: string
          updated_by?: string | null
          value: Json
        }
        Update: {
          description?: string | null
          key?: string
          scope_id?: string
          scope_type?: Database["public"]["Enums"]["config_scope"]
          updated_at?: string
          updated_by?: string | null
          value?: Json
        }
        Relationships: []
      }
      app_config_keys: {
        Row: {
          allowed_scopes: Database["public"]["Enums"]["config_scope"][]
          description: string | null
          key: string
          read_only: boolean
          value_schema: Json
        }
        Insert: {
          allowed_scopes?: Database["public"]["Enums"]["config_scope"][]
          description?: string | null
          key: string
          read_only?: boolean
          value_schema: Json
        }
        Update: {
          allowed_scopes?: Database["public"]["Enums"]["config_scope"][]
          description?: string | null
          key?: string
          read_only?: boolean
          value_schema?: Json
        }
        Relationships: []
      }
      audit_log: {
        Row: {
          action: string
          actor_id: string | null
          actor_role: string | null
          after: Json | null
          before: Json | null
          created_at: string
          id: number
          ip: unknown
          target_id: string
          target_type: string
          user_agent: string | null
        }
        Insert: {
          action: string
          actor_id?: string | null
          actor_role?: string | null
          after?: Json | null
          before?: Json | null
          created_at?: string
          id?: number
          ip?: unknown
          target_id: string
          target_type: string
          user_agent?: string | null
        }
        Update: {
          action?: string
          actor_id?: string | null
          actor_role?: string | null
          after?: Json | null
          before?: Json | null
          created_at?: string
          id?: number
          ip?: unknown
          target_id?: string
          target_type?: string
          user_agent?: string | null
        }
        Relationships: []
      }
      candidate_park_clusters: {
        Row: {
          centroid: unknown
          city_id: string
          created_at: string
          distinct_day_count: number
          distinct_driver_count: number
          first_seen: string
          id: string
          job_run_id: string
          last_seen: string
          reviewed_at: string | null
          reviewed_by: string | null
          route_stage_id: string | null
          sample_count: number
          status: string
        }
        Insert: {
          centroid: unknown
          city_id: string
          created_at?: string
          distinct_day_count: number
          distinct_driver_count: number
          first_seen: string
          id?: string
          job_run_id: string
          last_seen: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          route_stage_id?: string | null
          sample_count: number
          status?: string
        }
        Update: {
          centroid?: unknown
          city_id?: string
          created_at?: string
          distinct_day_count?: number
          distinct_driver_count?: number
          first_seen?: string
          id?: string
          job_run_id?: string
          last_seen?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          route_stage_id?: string | null
          sample_count?: number
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "candidate_park_clusters_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "candidate_park_clusters_job_run_id_fkey"
            columns: ["job_run_id"]
            isOneToOne: false
            referencedRelation: "job_runs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "candidate_park_clusters_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "candidate_park_clusters_route_stage_id_fkey"
            columns: ["route_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
        ]
      }
      cities: {
        Row: {
          boundary: unknown
          centroid: unknown
          country_code: string
          created_at: string
          id: string
          name: string
          slug: string
          state_region: string | null
          status: Database["public"]["Enums"]["city_status"]
          timezone: string | null
          updated_at: string
        }
        Insert: {
          boundary?: unknown
          centroid: unknown
          country_code: string
          created_at?: string
          id?: string
          name: string
          slug: string
          state_region?: string | null
          status?: Database["public"]["Enums"]["city_status"]
          timezone?: string | null
          updated_at?: string
        }
        Update: {
          boundary?: unknown
          centroid?: unknown
          country_code?: string
          created_at?: string
          id?: string
          name?: string
          slug?: string
          state_region?: string | null
          status?: Database["public"]["Enums"]["city_status"]
          timezone?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "cities_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
        ]
      }
      conductor_sessions: {
        Row: {
          code: string
          created_at: string
          created_by: string
          day_plan_id: string
          expires_at: string
          id: string
          layout_id: string
        }
        Insert: {
          code: string
          created_at?: string
          created_by: string
          day_plan_id: string
          expires_at: string
          id?: string
          layout_id: string
        }
        Update: {
          code?: string
          created_at?: string
          created_by?: string
          day_plan_id?: string
          expires_at?: string
          id?: string
          layout_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conductor_sessions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conductor_sessions_day_plan_id_fkey"
            columns: ["day_plan_id"]
            isOneToOne: false
            referencedRelation: "driver_day_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conductor_sessions_layout_id_fkey"
            columns: ["layout_id"]
            isOneToOne: false
            referencedRelation: "vehicle_layouts"
            referencedColumns: ["id"]
          },
        ]
      }
      corporate_accounts: {
        Row: {
          billing_address: string | null
          billing_email: string
          created_at: string
          currency: string
          deployment_id: string
          id: string
          monthly_budget: number | null
          name: string
          status: Database["public"]["Enums"]["corporate_account_status"]
          updated_at: string
        }
        Insert: {
          billing_address?: string | null
          billing_email: string
          created_at?: string
          currency?: string
          deployment_id: string
          id?: string
          monthly_budget?: number | null
          name: string
          status?: Database["public"]["Enums"]["corporate_account_status"]
          updated_at?: string
        }
        Update: {
          billing_address?: string | null
          billing_email?: string
          created_at?: string
          currency?: string
          deployment_id?: string
          id?: string
          monthly_budget?: number | null
          name?: string
          status?: Database["public"]["Enums"]["corporate_account_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "corporate_accounts_deployment_id_fkey"
            columns: ["deployment_id"]
            isOneToOne: false
            referencedRelation: "deployments"
            referencedColumns: ["id"]
          },
        ]
      }
      corporate_invoices: {
        Row: {
          corporate_account_id: string
          currency: string
          generated_at: string
          id: string
          period_end: string
          period_start: string
          status: Database["public"]["Enums"]["corporate_invoice_status"]
          total: number
        }
        Insert: {
          corporate_account_id: string
          currency: string
          generated_at?: string
          id?: string
          period_end: string
          period_start: string
          status?: Database["public"]["Enums"]["corporate_invoice_status"]
          total: number
        }
        Update: {
          corporate_account_id?: string
          currency?: string
          generated_at?: string
          id?: string
          period_end?: string
          period_start?: string
          status?: Database["public"]["Enums"]["corporate_invoice_status"]
          total?: number
        }
        Relationships: [
          {
            foreignKeyName: "corporate_invoices_corporate_account_id_fkey"
            columns: ["corporate_account_id"]
            isOneToOne: false
            referencedRelation: "corporate_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      corporate_members: {
        Row: {
          active: boolean
          corporate_account_id: string
          default_policy_id: string | null
          department: string | null
          employee_ref: string | null
          rider_id: string
          since: string
        }
        Insert: {
          active?: boolean
          corporate_account_id: string
          default_policy_id?: string | null
          department?: string | null
          employee_ref?: string | null
          rider_id: string
          since?: string
        }
        Update: {
          active?: boolean
          corporate_account_id?: string
          default_policy_id?: string | null
          department?: string | null
          employee_ref?: string | null
          rider_id?: string
          since?: string
        }
        Relationships: [
          {
            foreignKeyName: "corporate_members_corporate_account_id_fkey"
            columns: ["corporate_account_id"]
            isOneToOne: false
            referencedRelation: "corporate_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corporate_members_default_policy_id_fkey"
            columns: ["default_policy_id"]
            isOneToOne: false
            referencedRelation: "corporate_trip_policies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corporate_members_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
        ]
      }
      corporate_trip_allocations: {
        Row: {
          corporate_account_id: string
          created_at: string
          id: string
          policy_id: string
          subsidized_amount: number
          trip_id: string
        }
        Insert: {
          corporate_account_id: string
          created_at?: string
          id?: string
          policy_id: string
          subsidized_amount: number
          trip_id: string
        }
        Update: {
          corporate_account_id?: string
          created_at?: string
          id?: string
          policy_id?: string
          subsidized_amount?: number
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corporate_trip_allocations_corporate_account_id_fkey"
            columns: ["corporate_account_id"]
            isOneToOne: false
            referencedRelation: "corporate_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corporate_trip_allocations_policy_id_fkey"
            columns: ["policy_id"]
            isOneToOne: false
            referencedRelation: "corporate_trip_policies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corporate_trip_allocations_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: true
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      corporate_trip_policies: {
        Row: {
          active: boolean
          allowed_hours: Json | null
          allowed_zones: unknown
          corporate_account_id: string
          created_at: string
          id: string
          max_per_trip: number | null
          name: string
          subsidy_pct: number
          updated_at: string
        }
        Insert: {
          active?: boolean
          allowed_hours?: Json | null
          allowed_zones?: unknown
          corporate_account_id: string
          created_at?: string
          id?: string
          max_per_trip?: number | null
          name: string
          subsidy_pct: number
          updated_at?: string
        }
        Update: {
          active?: boolean
          allowed_hours?: Json | null
          allowed_zones?: unknown
          corporate_account_id?: string
          created_at?: string
          id?: string
          max_per_trip?: number | null
          name?: string
          subsidy_pct?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "corporate_trip_policies_corporate_account_id_fkey"
            columns: ["corporate_account_id"]
            isOneToOne: false
            referencedRelation: "corporate_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      corridors: {
        Row: {
          city_id: string
          created_at: string
          geometry: unknown
          id: string
          name: string
          slug: string
          status: Database["public"]["Enums"]["city_status"]
          updated_at: string
        }
        Insert: {
          city_id: string
          created_at?: string
          geometry?: unknown
          id?: string
          name: string
          slug: string
          status?: Database["public"]["Enums"]["city_status"]
          updated_at?: string
        }
        Update: {
          city_id?: string
          created_at?: string
          geometry?: unknown
          id?: string
          name?: string
          slug?: string
          status?: Database["public"]["Enums"]["city_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "corridors_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
        ]
      }
      countries: {
        Row: {
          active: boolean
          code: string
          created_at: string
          currency_code: string
          currency_minor_units: number
          currency_symbol: string
          default_locale: string
          deployment_id: string
          name: string
          phone_prefix: string
          regulatory_flags: Json
          timezone: string
          updated_at: string
          verification_schema: Json
        }
        Insert: {
          active?: boolean
          code: string
          created_at?: string
          currency_code: string
          currency_minor_units?: number
          currency_symbol: string
          default_locale?: string
          deployment_id: string
          name: string
          phone_prefix: string
          regulatory_flags?: Json
          timezone: string
          updated_at?: string
          verification_schema?: Json
        }
        Update: {
          active?: boolean
          code?: string
          created_at?: string
          currency_code?: string
          currency_minor_units?: number
          currency_symbol?: string
          default_locale?: string
          deployment_id?: string
          name?: string
          phone_prefix?: string
          regulatory_flags?: Json
          timezone?: string
          updated_at?: string
          verification_schema?: Json
        }
        Relationships: [
          {
            foreignKeyName: "countries_deployment_id_fkey"
            columns: ["deployment_id"]
            isOneToOne: false
            referencedRelation: "deployments"
            referencedColumns: ["id"]
          },
        ]
      }
      coverage_gap_reports: {
        Row: {
          ambient_vehicle_count: number
          city_id: string | null
          id: string
          nearest_known_stage_distance_m: number | null
          nearest_known_stage_id: string | null
          rider_id: string | null
          searched_at: string
          searched_destination: unknown
          searched_location: unknown
        }
        Insert: {
          ambient_vehicle_count?: number
          city_id?: string | null
          id?: string
          nearest_known_stage_distance_m?: number | null
          nearest_known_stage_id?: string | null
          rider_id?: string | null
          searched_at?: string
          searched_destination?: unknown
          searched_location: unknown
        }
        Update: {
          ambient_vehicle_count?: number
          city_id?: string | null
          id?: string
          nearest_known_stage_distance_m?: number | null
          nearest_known_stage_id?: string | null
          rider_id?: string | null
          searched_at?: string
          searched_destination?: unknown
          searched_location?: unknown
        }
        Relationships: [
          {
            foreignKeyName: "coverage_gap_reports_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "coverage_gap_reports_nearest_known_stage_id_fkey"
            columns: ["nearest_known_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "coverage_gap_reports_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
        ]
      }
      data_sources: {
        Row: {
          actor_profile_id: string | null
          created_at: string
          field_submission_id: string | null
          id: string
          job_run_id: string | null
          notes: string | null
          source_type: Database["public"]["Enums"]["source_type"]
          trip_id: string | null
        }
        Insert: {
          actor_profile_id?: string | null
          created_at?: string
          field_submission_id?: string | null
          id?: string
          job_run_id?: string | null
          notes?: string | null
          source_type: Database["public"]["Enums"]["source_type"]
          trip_id?: string | null
        }
        Update: {
          actor_profile_id?: string | null
          created_at?: string
          field_submission_id?: string | null
          id?: string
          job_run_id?: string | null
          notes?: string | null
          source_type?: Database["public"]["Enums"]["source_type"]
          trip_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "data_sources_actor_profile_id_fkey"
            columns: ["actor_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "data_sources_field_fk"
            columns: ["field_submission_id"]
            isOneToOne: false
            referencedRelation: "field_submissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "data_sources_job_fk"
            columns: ["job_run_id"]
            isOneToOne: false
            referencedRelation: "job_runs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "data_sources_trip_fk"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      deployments: {
        Row: {
          active: boolean
          branding_config: Json
          created_at: string
          id: string
          region_config: Json
          tenant_name: string
          updated_at: string
        }
        Insert: {
          active?: boolean
          branding_config?: Json
          created_at?: string
          id?: string
          region_config?: Json
          tenant_name: string
          updated_at?: string
        }
        Update: {
          active?: boolean
          branding_config?: Json
          created_at?: string
          id?: string
          region_config?: Json
          tenant_name?: string
          updated_at?: string
        }
        Relationships: []
      }
      device_installs: {
        Row: {
          device_model: string | null
          first_seen_at: string
          install_id: string
          last_seen_at: string
          profile_id: string
        }
        Insert: {
          device_model?: string | null
          first_seen_at?: string
          install_id: string
          last_seen_at?: string
          profile_id: string
        }
        Update: {
          device_model?: string | null
          first_seen_at?: string
          install_id?: string
          last_seen_at?: string
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "device_installs_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      device_tokens: {
        Row: {
          app: string
          platform: string
          profile_id: string
          token: string
          updated_at: string
        }
        Insert: {
          app: string
          platform: string
          profile_id: string
          token: string
          updated_at?: string
        }
        Update: {
          app?: string
          platform?: string
          profile_id?: string
          token?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "device_tokens_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_day_plans: {
        Row: {
          active: boolean
          corridor_id: string
          created_at: string
          driver_id: string
          home_label: string | null
          id: string
          layout_id: string
          route_id: string | null
          shift_end: string | null
          shift_start: string | null
          vehicle_id: string
        }
        Insert: {
          active?: boolean
          corridor_id: string
          created_at?: string
          driver_id: string
          home_label?: string | null
          id?: string
          layout_id: string
          route_id?: string | null
          shift_end?: string | null
          shift_start?: string | null
          vehicle_id: string
        }
        Update: {
          active?: boolean
          corridor_id?: string
          created_at?: string
          driver_id?: string
          home_label?: string | null
          id?: string
          layout_id?: string
          route_id?: string | null
          shift_end?: string | null
          shift_start?: string | null
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_day_plans_corridor_id_fkey"
            columns: ["corridor_id"]
            isOneToOne: false
            referencedRelation: "corridors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_day_plans_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_day_plans_layout_id_fkey"
            columns: ["layout_id"]
            isOneToOne: false
            referencedRelation: "vehicle_layouts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_day_plans_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_day_plans_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_earnings_goals: {
        Row: {
          driver_id: string
          target_minor: number | null
          updated_at: string
        }
        Insert: {
          driver_id: string
          target_minor?: number | null
          updated_at?: string
        }
        Update: {
          driver_id?: string
          target_minor?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_earnings_goals_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: true
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_ledger_entries: {
        Row: {
          amount: number
          balance_after: number
          created_at: string
          created_by_id: string | null
          created_by_type: Database["public"]["Enums"]["ledger_actor"]
          currency: string
          driver_id: string
          entry_type: Database["public"]["Enums"]["ledger_entry_type"]
          id: number
          idempotency_key: string
          memo: string | null
          settlement_id: string | null
          trip_extension_id: string | null
          trip_id: string | null
        }
        Insert: {
          amount: number
          balance_after: number
          created_at?: string
          created_by_id?: string | null
          created_by_type: Database["public"]["Enums"]["ledger_actor"]
          currency: string
          driver_id: string
          entry_type: Database["public"]["Enums"]["ledger_entry_type"]
          id?: number
          idempotency_key: string
          memo?: string | null
          settlement_id?: string | null
          trip_extension_id?: string | null
          trip_id?: string | null
        }
        Update: {
          amount?: number
          balance_after?: number
          created_at?: string
          created_by_id?: string | null
          created_by_type?: Database["public"]["Enums"]["ledger_actor"]
          currency?: string
          driver_id?: string
          entry_type?: Database["public"]["Enums"]["ledger_entry_type"]
          id?: number
          idempotency_key?: string
          memo?: string | null
          settlement_id?: string | null
          trip_extension_id?: string | null
          trip_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "dle_settlement_fk"
            columns: ["settlement_id"]
            isOneToOne: false
            referencedRelation: "settlements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_ledger_entries_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_ledger_entries_trip_extension_id_fkey"
            columns: ["trip_extension_id"]
            isOneToOne: false
            referencedRelation: "trip_extensions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_ledger_entries_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_payouts: {
        Row: {
          amount: number
          confirmed_at: string | null
          created_at: string
          currency: string
          driver_id: string
          id: string
          initiated_by: string
          ledger_entry_id: number | null
          provider_reference: string
          recipient_subaccount_code: string
          status: Database["public"]["Enums"]["driver_payout_status"]
        }
        Insert: {
          amount: number
          confirmed_at?: string | null
          created_at?: string
          currency: string
          driver_id: string
          id?: string
          initiated_by: string
          ledger_entry_id?: number | null
          provider_reference: string
          recipient_subaccount_code: string
          status?: Database["public"]["Enums"]["driver_payout_status"]
        }
        Update: {
          amount?: number
          confirmed_at?: string | null
          created_at?: string
          currency?: string
          driver_id?: string
          id?: string
          initiated_by?: string
          ledger_entry_id?: number | null
          provider_reference?: string
          recipient_subaccount_code?: string
          status?: Database["public"]["Enums"]["driver_payout_status"]
        }
        Relationships: [
          {
            foreignKeyName: "driver_payouts_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_payouts_initiated_by_fkey"
            columns: ["initiated_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_payouts_ledger_entry_id_fkey"
            columns: ["ledger_entry_id"]
            isOneToOne: false
            referencedRelation: "driver_ledger_entries"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_presence: {
        Row: {
          accuracy_m: number | null
          current_location: unknown
          declared_route_leg_id: string | null
          declared_route_profile_id: string | null
          driver_id: string
          heading: number | null
          last_ping_at: string
          nearest_stage_id: string | null
          park_id: string | null
          seats_available: number
          session_id: string
          speed_mps: number | null
          started_at: string
          status: Database["public"]["Enums"]["presence_status"]
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          accuracy_m?: number | null
          current_location: unknown
          declared_route_leg_id?: string | null
          declared_route_profile_id?: string | null
          driver_id: string
          heading?: number | null
          last_ping_at?: string
          nearest_stage_id?: string | null
          park_id?: string | null
          seats_available: number
          session_id?: string
          speed_mps?: number | null
          started_at?: string
          status: Database["public"]["Enums"]["presence_status"]
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          accuracy_m?: number | null
          current_location?: unknown
          declared_route_leg_id?: string | null
          declared_route_profile_id?: string | null
          driver_id?: string
          heading?: number | null
          last_ping_at?: string
          nearest_stage_id?: string | null
          park_id?: string | null
          seats_available?: number
          session_id?: string
          speed_mps?: number | null
          started_at?: string
          status?: Database["public"]["Enums"]["presence_status"]
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_presence_declared_route_leg_id_fkey"
            columns: ["declared_route_leg_id"]
            isOneToOne: false
            referencedRelation: "route_legs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_presence_declared_route_profile_id_fkey"
            columns: ["declared_route_profile_id"]
            isOneToOne: false
            referencedRelation: "driver_route_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_presence_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: true
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_presence_nearest_stage_id_fkey"
            columns: ["nearest_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_presence_park_id_fkey"
            columns: ["park_id"]
            isOneToOne: false
            referencedRelation: "parks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_presence_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_presence_history: {
        Row: {
          downsampled: boolean
          driver_id: string
          heading: number | null
          id: number
          location: unknown
          session_id: string
          speed_mps: number | null
          status: Database["public"]["Enums"]["presence_status"]
          ts: string
        }
        Insert: {
          downsampled?: boolean
          driver_id: string
          heading?: number | null
          id?: number
          location: unknown
          session_id: string
          speed_mps?: number | null
          status: Database["public"]["Enums"]["presence_status"]
          ts: string
        }
        Update: {
          downsampled?: boolean
          driver_id?: string
          heading?: number | null
          id?: number
          location?: unknown
          session_id?: string
          speed_mps?: number | null
          status?: Database["public"]["Enums"]["presence_status"]
          ts?: string
        }
        Relationships: []
      }
      driver_presence_history_y2026_m10: {
        Row: {
          downsampled: boolean
          driver_id: string
          heading: number | null
          id: number
          location: unknown
          session_id: string
          speed_mps: number | null
          status: Database["public"]["Enums"]["presence_status"]
          ts: string
        }
        Insert: {
          downsampled?: boolean
          driver_id: string
          heading?: number | null
          id?: number
          location: unknown
          session_id: string
          speed_mps?: number | null
          status: Database["public"]["Enums"]["presence_status"]
          ts: string
        }
        Update: {
          downsampled?: boolean
          driver_id?: string
          heading?: number | null
          id?: number
          location?: unknown
          session_id?: string
          speed_mps?: number | null
          status?: Database["public"]["Enums"]["presence_status"]
          ts?: string
        }
        Relationships: []
      }
      driver_presence_history_y2026_m11: {
        Row: {
          downsampled: boolean
          driver_id: string
          heading: number | null
          id: number
          location: unknown
          session_id: string
          speed_mps: number | null
          status: Database["public"]["Enums"]["presence_status"]
          ts: string
        }
        Insert: {
          downsampled?: boolean
          driver_id: string
          heading?: number | null
          id?: number
          location: unknown
          session_id: string
          speed_mps?: number | null
          status: Database["public"]["Enums"]["presence_status"]
          ts: string
        }
        Update: {
          downsampled?: boolean
          driver_id?: string
          heading?: number | null
          id?: number
          location?: unknown
          session_id?: string
          speed_mps?: number | null
          status?: Database["public"]["Enums"]["presence_status"]
          ts?: string
        }
        Relationships: []
      }
      driver_presence_history_y2026_m12: {
        Row: {
          downsampled: boolean
          driver_id: string
          heading: number | null
          id: number
          location: unknown
          session_id: string
          speed_mps: number | null
          status: Database["public"]["Enums"]["presence_status"]
          ts: string
        }
        Insert: {
          downsampled?: boolean
          driver_id: string
          heading?: number | null
          id?: number
          location: unknown
          session_id: string
          speed_mps?: number | null
          status: Database["public"]["Enums"]["presence_status"]
          ts: string
        }
        Update: {
          downsampled?: boolean
          driver_id?: string
          heading?: number | null
          id?: number
          location?: unknown
          session_id?: string
          speed_mps?: number | null
          status?: Database["public"]["Enums"]["presence_status"]
          ts?: string
        }
        Relationships: []
      }
      driver_rest_prefs: {
        Row: {
          drive_minutes: number | null
          driver_id: string
          rest_minutes: number | null
          updated_at: string
        }
        Insert: {
          drive_minutes?: number | null
          driver_id: string
          rest_minutes?: number | null
          updated_at?: string
        }
        Update: {
          drive_minutes?: number | null
          driver_id?: string
          rest_minutes?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_rest_prefs_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: true
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_rests: {
        Row: {
          created_at: string
          driver_id: string
          ended_at: string
          id: string
          idempotency_key: string
          priority_until: string | null
          qualified: boolean
          started_at: string
        }
        Insert: {
          created_at?: string
          driver_id: string
          ended_at: string
          id?: string
          idempotency_key: string
          priority_until?: string | null
          qualified: boolean
          started_at: string
        }
        Update: {
          created_at?: string
          driver_id?: string
          ended_at?: string
          id?: string
          idempotency_key?: string
          priority_until?: string | null
          qualified?: boolean
          started_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_rests_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_ride_rules: {
        Row: {
          body: string | null
          created_at: string
          driver_id: string
          effect: string
          enabled: boolean
          id: string
          params: Json
          preset_id: string | null
          target_ref: string | null
          target_scope: string
          title: string
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          body?: string | null
          created_at?: string
          driver_id: string
          effect: string
          enabled?: boolean
          id?: string
          params?: Json
          preset_id?: string | null
          target_ref?: string | null
          target_scope: string
          title: string
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          body?: string | null
          created_at?: string
          driver_id?: string
          effect?: string
          enabled?: boolean
          id?: string
          params?: Json
          preset_id?: string | null
          target_ref?: string | null
          target_scope?: string
          title?: string
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_ride_rules_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_ride_rules_preset_id_fkey"
            columns: ["preset_id"]
            isOneToOne: false
            referencedRelation: "ride_rule_presets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_ride_rules_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_risk_scores: {
        Row: {
          actioned_flags: number
          cancel_after_match_rate: number
          cancels_after_match: number
          cash_cancels_after_match: number
          computed_at: string
          driver_id: string
          open_flags: number
          trips_matched: number
          window_end: string
          window_start: string
        }
        Insert: {
          actioned_flags: number
          cancel_after_match_rate: number
          cancels_after_match: number
          cash_cancels_after_match: number
          computed_at?: string
          driver_id: string
          open_flags: number
          trips_matched: number
          window_end: string
          window_start: string
        }
        Update: {
          actioned_flags?: number
          cancel_after_match_rate?: number
          cancels_after_match?: number
          cash_cancels_after_match?: number
          computed_at?: string
          driver_id?: string
          open_flags?: number
          trips_matched?: number
          window_end?: string
          window_start?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_risk_scores_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_route_profiles: {
        Row: {
          active: boolean
          created_at: string
          driver_id: string
          id: string
          load_surcharge_amount: number | null
          load_surcharge_currency: string | null
          mode_code: string
          name: string | null
          route_id: string | null
          updated_at: string
        }
        Insert: {
          active?: boolean
          created_at?: string
          driver_id: string
          id?: string
          load_surcharge_amount?: number | null
          load_surcharge_currency?: string | null
          mode_code: string
          name?: string | null
          route_id?: string | null
          updated_at?: string
        }
        Update: {
          active?: boolean
          created_at?: string
          driver_id?: string
          id?: string
          load_surcharge_amount?: number | null
          load_surcharge_currency?: string | null
          mode_code?: string
          name?: string | null
          route_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_route_profiles_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_route_profiles_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "driver_route_profiles_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_route_stops: {
        Row: {
          created_at: string
          currency: string
          custom_label: string | null
          custom_location: unknown
          id: string
          price_to_end: number
          profile_id: string
          route_stage_id: string | null
          sequence: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          currency: string
          custom_label?: string | null
          custom_location?: unknown
          id?: string
          price_to_end: number
          profile_id: string
          route_stage_id?: string | null
          sequence: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          currency?: string
          custom_label?: string | null
          custom_location?: unknown
          id?: string
          price_to_end?: number
          profile_id?: string
          route_stage_id?: string | null
          sequence?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_route_stops_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "driver_route_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_route_stops_route_stage_id_fkey"
            columns: ["route_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_standing_transitions: {
        Row: {
          actor_id: string | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          balance_at: number | null
          created_at: string
          driver_id: string
          from_standing: Database["public"]["Enums"]["driver_standing"] | null
          id: number
          reason: string
          to_standing: Database["public"]["Enums"]["driver_standing"]
        }
        Insert: {
          actor_id?: string | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          balance_at?: number | null
          created_at?: string
          driver_id: string
          from_standing?: Database["public"]["Enums"]["driver_standing"] | null
          id?: number
          reason: string
          to_standing: Database["public"]["Enums"]["driver_standing"]
        }
        Update: {
          actor_id?: string | null
          actor_type?: Database["public"]["Enums"]["actor_type"]
          balance_at?: number | null
          created_at?: string
          driver_id?: string
          from_standing?: Database["public"]["Enums"]["driver_standing"] | null
          id?: number
          reason?: string
          to_standing?: Database["public"]["Enums"]["driver_standing"]
        }
        Relationships: [
          {
            foreignKeyName: "driver_standing_transitions_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_vehicles: {
        Row: {
          active: boolean
          driver_id: string
          since: string
          vehicle_id: string
        }
        Insert: {
          active?: boolean
          driver_id: string
          since?: string
          vehicle_id: string
        }
        Update: {
          active?: boolean
          driver_id?: string
          since?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_vehicles_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_vehicles_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_verifications: {
        Row: {
          country_code: string
          created_at: string
          document_type: string
          driver_id: string
          expires_at: string | null
          face_match_score: number | null
          id: string
          ocr_extract: Json | null
          provider: string | null
          provider_reference: string | null
          rejection_reason: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["public"]["Enums"]["doc_status"]
          storage_path: string | null
          submitted_at: string
          updated_at: string
          vehicle_id: string | null
        }
        Insert: {
          country_code: string
          created_at?: string
          document_type: string
          driver_id: string
          expires_at?: string | null
          face_match_score?: number | null
          id?: string
          ocr_extract?: Json | null
          provider?: string | null
          provider_reference?: string | null
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["doc_status"]
          storage_path?: string | null
          submitted_at?: string
          updated_at?: string
          vehicle_id?: string | null
        }
        Update: {
          country_code?: string
          created_at?: string
          document_type?: string
          driver_id?: string
          expires_at?: string | null
          face_match_score?: number | null
          id?: string
          ocr_extract?: Json | null
          provider?: string | null
          provider_reference?: string | null
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["doc_status"]
          storage_path?: string | null
          submitted_at?: string
          updated_at?: string
          vehicle_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "driver_verifications_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "driver_verifications_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_verifications_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_verifications_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      drivers: {
        Row: {
          accepts_digital: boolean
          city_id: string
          created_at: string
          driver_code: string | null
          driver_code_rotated_at: string | null
          home_park_id: string | null
          id: string
          payout_bank_last4: string | null
          payout_bank_name: string | null
          payout_subaccount_code: string | null
          rating: number | null
          rating_count: number
          standing: Database["public"]["Enums"]["driver_standing"]
          standing_since: string
          tenure_started_at: string | null
          updated_at: string
          verified_status: Database["public"]["Enums"]["verified_status"]
          women_only_eligible: boolean
        }
        Insert: {
          accepts_digital?: boolean
          city_id: string
          created_at?: string
          driver_code?: string | null
          driver_code_rotated_at?: string | null
          home_park_id?: string | null
          id: string
          payout_bank_last4?: string | null
          payout_bank_name?: string | null
          payout_subaccount_code?: string | null
          rating?: number | null
          rating_count?: number
          standing?: Database["public"]["Enums"]["driver_standing"]
          standing_since?: string
          tenure_started_at?: string | null
          updated_at?: string
          verified_status?: Database["public"]["Enums"]["verified_status"]
          women_only_eligible?: boolean
        }
        Update: {
          accepts_digital?: boolean
          city_id?: string
          created_at?: string
          driver_code?: string | null
          driver_code_rotated_at?: string | null
          home_park_id?: string | null
          id?: string
          payout_bank_last4?: string | null
          payout_bank_name?: string | null
          payout_subaccount_code?: string | null
          rating?: number | null
          rating_count?: number
          standing?: Database["public"]["Enums"]["driver_standing"]
          standing_since?: string
          tenure_started_at?: string | null
          updated_at?: string
          verified_status?: Database["public"]["Enums"]["verified_status"]
          women_only_eligible?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "drivers_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "drivers_home_park_fk"
            columns: ["home_park_id"]
            isOneToOne: false
            referencedRelation: "parks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "drivers_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      emergency_contacts: {
        Row: {
          created_at: string
          display_name: string
          id: string
          phone_e164: string
          profile_id: string
        }
        Insert: {
          created_at?: string
          display_name: string
          id?: string
          phone_e164: string
          profile_id: string
        }
        Update: {
          created_at?: string
          display_name?: string
          id?: string
          phone_e164?: string
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "emergency_contacts_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      fare_corrections: {
        Row: {
          created_at: string
          currency: string
          fare_shown: number | null
          from_stage_id: string | null
          id: string
          proposed_fare: number
          review_note: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          route_id: string | null
          route_leg_id: string | null
          route_through_fare_id: string | null
          source_id: string
          status: Database["public"]["Enums"]["correction_status"]
          submitted_by: string
          submitter_role: string
          to_stage_id: string | null
          trip_id: string | null
        }
        Insert: {
          created_at?: string
          currency: string
          fare_shown?: number | null
          from_stage_id?: string | null
          id?: string
          proposed_fare: number
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          route_id?: string | null
          route_leg_id?: string | null
          route_through_fare_id?: string | null
          source_id: string
          status?: Database["public"]["Enums"]["correction_status"]
          submitted_by: string
          submitter_role: string
          to_stage_id?: string | null
          trip_id?: string | null
        }
        Update: {
          created_at?: string
          currency?: string
          fare_shown?: number | null
          from_stage_id?: string | null
          id?: string
          proposed_fare?: number
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          route_id?: string | null
          route_leg_id?: string | null
          route_through_fare_id?: string | null
          source_id?: string
          status?: Database["public"]["Enums"]["correction_status"]
          submitted_by?: string
          submitter_role?: string
          to_stage_id?: string | null
          trip_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fare_corrections_from_stage_id_fkey"
            columns: ["from_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_corrections_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_corrections_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_corrections_route_leg_id_fkey"
            columns: ["route_leg_id"]
            isOneToOne: false
            referencedRelation: "route_legs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_corrections_route_through_fare_id_fkey"
            columns: ["route_through_fare_id"]
            isOneToOne: false
            referencedRelation: "route_through_fares"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_corrections_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "data_sources"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_corrections_submitted_by_fkey"
            columns: ["submitted_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_corrections_to_stage_id_fkey"
            columns: ["to_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fc_trip_fk"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      fare_observations: {
        Row: {
          amount_minor: number
          client_ref: string
          corridor_label: string
          created_at: string
          hour_of_day: number
          id: string
          kind: string
          rider_id: string
        }
        Insert: {
          amount_minor: number
          client_ref: string
          corridor_label: string
          created_at?: string
          hour_of_day: number
          id?: string
          kind: string
          rider_id: string
        }
        Update: {
          amount_minor?: number
          client_ref?: string
          corridor_label?: string
          created_at?: string
          hour_of_day?: number
          id?: string
          kind?: string
          rider_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fare_observations_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      fare_quotes: {
        Row: {
          amount: number
          components: Json
          confidence: number
          created_at: string
          currency: string
          driver_id: string | null
          driver_route_profile_id: string | null
          expires_at: string
          from_location: unknown
          from_stage_id: string | null
          id: string
          mode_code: string
          negotiation_id: string | null
          rider_id: string | null
          route_id: string | null
          tier: number
          to_location: unknown
          to_stage_id: string | null
        }
        Insert: {
          amount: number
          components: Json
          confidence: number
          created_at?: string
          currency: string
          driver_id?: string | null
          driver_route_profile_id?: string | null
          expires_at?: string
          from_location?: unknown
          from_stage_id?: string | null
          id?: string
          mode_code: string
          negotiation_id?: string | null
          rider_id?: string | null
          route_id?: string | null
          tier: number
          to_location?: unknown
          to_stage_id?: string | null
        }
        Update: {
          amount?: number
          components?: Json
          confidence?: number
          created_at?: string
          currency?: string
          driver_id?: string | null
          driver_route_profile_id?: string | null
          expires_at?: string
          from_location?: unknown
          from_stage_id?: string | null
          id?: string
          mode_code?: string
          negotiation_id?: string | null
          rider_id?: string | null
          route_id?: string | null
          tier?: number
          to_location?: unknown
          to_stage_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fare_quotes_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_quotes_driver_route_profile_fk"
            columns: ["driver_route_profile_id"]
            isOneToOne: false
            referencedRelation: "driver_route_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_quotes_from_stage_id_fkey"
            columns: ["from_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_quotes_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "fare_quotes_negotiation_fk"
            columns: ["negotiation_id"]
            isOneToOne: false
            referencedRelation: "price_negotiations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_quotes_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_quotes_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fare_quotes_to_stage_id_fkey"
            columns: ["to_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
        ]
      }
      field_agents: {
        Row: {
          active: boolean
          city_id: string
          created_at: string
          id: string
          updated_at: string
        }
        Insert: {
          active?: boolean
          city_id: string
          created_at?: string
          id: string
          updated_at?: string
        }
        Update: {
          active?: boolean
          city_id?: string
          created_at?: string
          id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "field_agents_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "field_agents_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      field_reconciliations: {
        Row: {
          created_at: string
          entity_key: string
          entity_type: string
          id: string
          published_target_id: string | null
          published_target_type: string | null
          resolution: Json | null
          resolved_at: string | null
          resolved_by: string | null
          status: string
          submission_a: string
          submission_b: string | null
          submission_c: string | null
          updated_at: string
          variance: Json | null
        }
        Insert: {
          created_at?: string
          entity_key: string
          entity_type: string
          id?: string
          published_target_id?: string | null
          published_target_type?: string | null
          resolution?: Json | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          submission_a: string
          submission_b?: string | null
          submission_c?: string | null
          updated_at?: string
          variance?: Json | null
        }
        Update: {
          created_at?: string
          entity_key?: string
          entity_type?: string
          id?: string
          published_target_id?: string | null
          published_target_type?: string | null
          resolution?: Json | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          submission_a?: string
          submission_b?: string | null
          submission_c?: string | null
          updated_at?: string
          variance?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "field_reconciliations_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "field_reconciliations_submission_a_fkey"
            columns: ["submission_a"]
            isOneToOne: false
            referencedRelation: "field_submissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "field_reconciliations_submission_b_fkey"
            columns: ["submission_b"]
            isOneToOne: false
            referencedRelation: "field_submissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "field_reconciliations_submission_c_fkey"
            columns: ["submission_c"]
            isOneToOne: false
            referencedRelation: "field_submissions"
            referencedColumns: ["id"]
          },
        ]
      }
      field_submissions: {
        Row: {
          city_id: string
          corridor_id: string | null
          created_at: string
          entity_key: string
          entity_type: string
          form_id: string
          form_version: string
          gpx_storage_path: string | null
          id: string
          payload: Json
          scout_profile_id: string
          status: string
          submission_uid: string
          submitted_at: string
        }
        Insert: {
          city_id: string
          corridor_id?: string | null
          created_at?: string
          entity_key: string
          entity_type: string
          form_id: string
          form_version: string
          gpx_storage_path?: string | null
          id?: string
          payload: Json
          scout_profile_id: string
          status?: string
          submission_uid: string
          submitted_at: string
        }
        Update: {
          city_id?: string
          corridor_id?: string | null
          created_at?: string
          entity_key?: string
          entity_type?: string
          form_id?: string
          form_version?: string
          gpx_storage_path?: string | null
          id?: string
          payload?: Json
          scout_profile_id?: string
          status?: string
          submission_uid?: string
          submitted_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "field_submissions_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "field_submissions_corridor_id_fkey"
            columns: ["corridor_id"]
            isOneToOne: false
            referencedRelation: "corridors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "field_submissions_scout_profile_id_fkey"
            columns: ["scout_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      fuel_notes: {
        Row: {
          client_ref: string
          created_at: string
          driver_id: string
          id: string
          label: string
          lat: number
          lng: number
          price_naira: number
        }
        Insert: {
          client_ref: string
          created_at?: string
          driver_id: string
          id?: string
          label: string
          lat: number
          lng: number
          price_naira: number
        }
        Update: {
          client_ref?: string
          created_at?: string
          driver_id?: string
          id?: string
          label?: string
          lat?: number
          lng?: number
          price_naira?: number
        }
        Relationships: [
          {
            foreignKeyName: "fuel_notes_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
        ]
      }
      graph_confirmations: {
        Row: {
          confirmer_profile_id: string
          confirmer_role: string
          created_at: string
          id: string
          meta: Json
          proposed_value: Json
          source_id: string
          target_id: string
          target_type: string
          trip_id: string | null
          trust_weight: number
        }
        Insert: {
          confirmer_profile_id: string
          confirmer_role: string
          created_at?: string
          id?: string
          meta?: Json
          proposed_value: Json
          source_id: string
          target_id: string
          target_type: string
          trip_id?: string | null
          trust_weight: number
        }
        Update: {
          confirmer_profile_id?: string
          confirmer_role?: string
          created_at?: string
          id?: string
          meta?: Json
          proposed_value?: Json
          source_id?: string
          target_id?: string
          target_type?: string
          trip_id?: string | null
          trust_weight?: number
        }
        Relationships: [
          {
            foreignKeyName: "gc_trip_fk"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "graph_confirmations_confirmer_profile_id_fkey"
            columns: ["confirmer_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "graph_confirmations_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "data_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      graph_revisions: {
        Row: {
          after: Json
          before: Json | null
          changed_by: string | null
          created_at: string
          id: number
          reason: string | null
          source_id: string | null
          target_id: string
          target_type: string
        }
        Insert: {
          after: Json
          before?: Json | null
          changed_by?: string | null
          created_at?: string
          id?: number
          reason?: string | null
          source_id?: string | null
          target_id: string
          target_type: string
        }
        Update: {
          after?: Json
          before?: Json | null
          changed_by?: string | null
          created_at?: string
          id?: number
          reason?: string | null
          source_id?: string | null
          target_id?: string
          target_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "graph_revisions_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "data_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      guarantors: {
        Row: {
          acknowledged_at: string | null
          created_at: string
          driver_id: string
          guarantor_name: string
          guarantor_phone_e164: string
          guarantor_profile_id: string | null
          guarantor_type: Database["public"]["Enums"]["guarantor_type"]
          id: string
          last_notified_at: string | null
          updated_at: string
        }
        Insert: {
          acknowledged_at?: string | null
          created_at?: string
          driver_id: string
          guarantor_name: string
          guarantor_phone_e164: string
          guarantor_profile_id?: string | null
          guarantor_type: Database["public"]["Enums"]["guarantor_type"]
          id?: string
          last_notified_at?: string | null
          updated_at?: string
        }
        Update: {
          acknowledged_at?: string | null
          created_at?: string
          driver_id?: string
          guarantor_name?: string
          guarantor_phone_e164?: string
          guarantor_profile_id?: string | null
          guarantor_type?: Database["public"]["Enums"]["guarantor_type"]
          id?: string
          last_notified_at?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "guarantors_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "guarantors_guarantor_profile_id_fkey"
            columns: ["guarantor_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      guardian_events: {
        Row: {
          created_at: string
          escalated: boolean
          id: string
          idempotency_key: string
          kind: string
          rider_id: string
          trip_id: string
        }
        Insert: {
          created_at?: string
          escalated?: boolean
          id?: string
          idempotency_key: string
          kind: string
          rider_id: string
          trip_id: string
        }
        Update: {
          created_at?: string
          escalated?: boolean
          id?: string
          idempotency_key?: string
          kind?: string
          rider_id?: string
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "guardian_events_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "guardian_events_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      incidents: {
        Row: {
          assigned_to: string | null
          attachment_paths: string[]
          description: string | null
          id: string
          reported_at: string
          reported_by: string
          reported_role: string
          resolution_note: string | null
          resolved_at: string | null
          severity: number
          status: Database["public"]["Enums"]["incident_status"]
          trip_id: string | null
          type: Database["public"]["Enums"]["incident_type"]
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          attachment_paths?: string[]
          description?: string | null
          id?: string
          reported_at?: string
          reported_by: string
          reported_role: string
          resolution_note?: string | null
          resolved_at?: string | null
          severity?: number
          status?: Database["public"]["Enums"]["incident_status"]
          trip_id?: string | null
          type: Database["public"]["Enums"]["incident_type"]
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          attachment_paths?: string[]
          description?: string | null
          id?: string
          reported_at?: string
          reported_by?: string
          reported_role?: string
          resolution_note?: string | null
          resolved_at?: string | null
          severity?: number
          status?: Database["public"]["Enums"]["incident_status"]
          trip_id?: string | null
          type?: Database["public"]["Enums"]["incident_type"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "incidents_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incidents_reported_by_fkey"
            columns: ["reported_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incidents_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      invoice_lines: {
        Row: {
          allocation_id: string
          amount: number
          id: string
          invoice_id: string
        }
        Insert: {
          allocation_id: string
          amount: number
          id?: string
          invoice_id: string
        }
        Update: {
          allocation_id?: string
          amount?: number
          id?: string
          invoice_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "invoice_lines_allocation_id_fkey"
            columns: ["allocation_id"]
            isOneToOne: true
            referencedRelation: "corporate_trip_allocations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoice_lines_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "corporate_invoices"
            referencedColumns: ["id"]
          },
        ]
      }
      itineraries: {
        Row: {
          created_at: string
          id: string
          load_flagged: boolean
          load_note: string | null
          load_size: Database["public"]["Enums"]["load_size"] | null
          plan_date: string
          rider_id: string
          status: Database["public"]["Enums"]["itinerary_status"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          load_flagged?: boolean
          load_note?: string | null
          load_size?: Database["public"]["Enums"]["load_size"] | null
          plan_date?: string
          rider_id: string
          status?: Database["public"]["Enums"]["itinerary_status"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          load_flagged?: boolean
          load_note?: string | null
          load_size?: Database["public"]["Enums"]["load_size"] | null
          plan_date?: string
          rider_id?: string
          status?: Database["public"]["Enums"]["itinerary_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "itineraries_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
        ]
      }
      itinerary_stops: {
        Row: {
          created_at: string
          destination_description: string
          destination_location: unknown
          id: string
          itinerary_id: string
          linked_journey_id: string | null
          prepared_plan: Json | null
          sequence: number
          status: Database["public"]["Enums"]["stop_status"]
          target_time: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          destination_description: string
          destination_location?: unknown
          id?: string
          itinerary_id: string
          linked_journey_id?: string | null
          prepared_plan?: Json | null
          sequence: number
          status?: Database["public"]["Enums"]["stop_status"]
          target_time?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          destination_description?: string
          destination_location?: unknown
          id?: string
          itinerary_id?: string
          linked_journey_id?: string | null
          prepared_plan?: Json | null
          sequence?: number
          status?: Database["public"]["Enums"]["stop_status"]
          target_time?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "itinerary_stops_itinerary_id_fkey"
            columns: ["itinerary_id"]
            isOneToOne: false
            referencedRelation: "itineraries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "itinerary_stops_linked_journey_id_fkey"
            columns: ["linked_journey_id"]
            isOneToOne: false
            referencedRelation: "journeys"
            referencedColumns: ["id"]
          },
        ]
      }
      job_runs: {
        Row: {
          error: string | null
          finished_at: string | null
          id: string
          job_name: string
          params: Json | null
          started_at: string
          stats: Json | null
          status: string
        }
        Insert: {
          error?: string | null
          finished_at?: string | null
          id?: string
          job_name: string
          params?: Json | null
          started_at?: string
          stats?: Json | null
          status?: string
        }
        Update: {
          error?: string | null
          finished_at?: string | null
          id?: string
          job_name?: string
          params?: Json | null
          started_at?: string
          stats?: Json | null
          status?: string
        }
        Relationships: []
      }
      journey_transfer_walks: {
        Row: {
          after_trip_sequence: number
          directions: Json
          from_location: unknown
          id: string
          journey_id: string
          prefetched_at: string
          to_location: unknown
        }
        Insert: {
          after_trip_sequence: number
          directions: Json
          from_location: unknown
          id?: string
          journey_id: string
          prefetched_at?: string
          to_location: unknown
        }
        Update: {
          after_trip_sequence?: number
          directions?: Json
          from_location?: unknown
          id?: string
          journey_id?: string
          prefetched_at?: string
          to_location?: unknown
        }
        Relationships: [
          {
            foreignKeyName: "journey_transfer_walks_journey_id_fkey"
            columns: ["journey_id"]
            isOneToOne: false
            referencedRelation: "journeys"
            referencedColumns: ["id"]
          },
        ]
      }
      journeys: {
        Row: {
          city_id: string
          completed_at: string | null
          created_at: string
          current_trip_sequence: number
          destination: unknown
          destination_label: string | null
          id: string
          itinerary_stop_id: string | null
          load_flagged: boolean
          load_note: string | null
          load_size: Database["public"]["Enums"]["load_size"] | null
          origin: unknown
          plan_snapshot: Json
          planner_query_id: string | null
          rider_id: string
          status: Database["public"]["Enums"]["journey_status"]
          updated_at: string
          women_only: boolean
        }
        Insert: {
          city_id: string
          completed_at?: string | null
          created_at?: string
          current_trip_sequence?: number
          destination: unknown
          destination_label?: string | null
          id?: string
          itinerary_stop_id?: string | null
          load_flagged?: boolean
          load_note?: string | null
          load_size?: Database["public"]["Enums"]["load_size"] | null
          origin: unknown
          plan_snapshot: Json
          planner_query_id?: string | null
          rider_id: string
          status?: Database["public"]["Enums"]["journey_status"]
          updated_at?: string
          women_only?: boolean
        }
        Update: {
          city_id?: string
          completed_at?: string | null
          created_at?: string
          current_trip_sequence?: number
          destination?: unknown
          destination_label?: string | null
          id?: string
          itinerary_stop_id?: string | null
          load_flagged?: boolean
          load_note?: string | null
          load_size?: Database["public"]["Enums"]["load_size"] | null
          origin?: unknown
          plan_snapshot?: Json
          planner_query_id?: string | null
          rider_id?: string
          status?: Database["public"]["Enums"]["journey_status"]
          updated_at?: string
          women_only?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "journeys_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journeys_planner_query_id_fkey"
            columns: ["planner_query_id"]
            isOneToOne: false
            referencedRelation: "planner_queries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journeys_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journeys_stop_fk"
            columns: ["itinerary_stop_id"]
            isOneToOne: false
            referencedRelation: "itinerary_stops"
            referencedColumns: ["id"]
          },
        ]
      }
      live_segment_observations: {
        Row: {
          city_id: string
          created_at: string
          id: string
          observed_at: string
          segment_key: string
          speed_mps: number
          trip_id: string | null
        }
        Insert: {
          city_id: string
          created_at?: string
          id?: string
          observed_at: string
          segment_key: string
          speed_mps: number
          trip_id?: string | null
        }
        Update: {
          city_id?: string
          created_at?: string
          id?: string
          observed_at?: string
          segment_key?: string
          speed_mps?: number
          trip_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "live_segment_observations_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_segment_observations_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      matched_traces: {
        Row: {
          actor_type: Database["public"]["Enums"]["actor_type"]
          confidence: number
          created_at: string
          geometry: unknown
          id: string
          match_meta: Json | null
          osm_way_ids: number[]
          trip_id: string
        }
        Insert: {
          actor_type: Database["public"]["Enums"]["actor_type"]
          confidence: number
          created_at?: string
          geometry: unknown
          id?: string
          match_meta?: Json | null
          osm_way_ids?: number[]
          trip_id: string
        }
        Update: {
          actor_type?: Database["public"]["Enums"]["actor_type"]
          confidence?: number
          created_at?: string
          geometry?: unknown
          id?: string
          match_meta?: Json | null
          osm_way_ids?: number[]
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "matched_traces_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      mode_config: {
        Row: {
          active: boolean
          code: string
          color_token: string
          comfort_weight: number
          created_at: string
          default_dwell_s: number
          default_seat_capacity: number
          icon_key: string
          label: string
          label_i18n: Json
          layout_preset: Json | null
          load_capacity: string
          review_seat_max: number | null
          sort_order: number
          updated_at: string
        }
        Insert: {
          active?: boolean
          code: string
          color_token: string
          comfort_weight: number
          created_at?: string
          default_dwell_s?: number
          default_seat_capacity: number
          icon_key: string
          label: string
          label_i18n?: Json
          layout_preset?: Json | null
          load_capacity: string
          review_seat_max?: number | null
          sort_order?: number
          updated_at?: string
        }
        Update: {
          active?: boolean
          code?: string
          color_token?: string
          comfort_weight?: number
          created_at?: string
          default_dwell_s?: number
          default_seat_capacity?: number
          icon_key?: string
          label?: string
          label_i18n?: Json
          layout_preset?: Json | null
          load_capacity?: string
          review_seat_max?: number | null
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      notifications: {
        Row: {
          channels: string[]
          created_at: string
          id: string
          payload: Json
          profile_id: string
          read_at: string | null
          sent_at: string | null
          type: string
        }
        Insert: {
          channels?: string[]
          created_at?: string
          id?: string
          payload: Json
          profile_id: string
          read_at?: string | null
          sent_at?: string | null
          type: string
        }
        Update: {
          channels?: string[]
          created_at?: string
          id?: string
          payload?: Json
          profile_id?: string
          read_at?: string | null
          sent_at?: string | null
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      operator_accounts: {
        Row: {
          billing_status: Database["public"]["Enums"]["operator_billing_status"]
          created_at: string
          deployment_id: string
          id: string
          name: string
          subscription_tier: string
          type: Database["public"]["Enums"]["operator_account_type"]
        }
        Insert: {
          billing_status?: Database["public"]["Enums"]["operator_billing_status"]
          created_at?: string
          deployment_id: string
          id?: string
          name: string
          subscription_tier?: string
          type: Database["public"]["Enums"]["operator_account_type"]
        }
        Update: {
          billing_status?: Database["public"]["Enums"]["operator_billing_status"]
          created_at?: string
          deployment_id?: string
          id?: string
          name?: string
          subscription_tier?: string
          type?: Database["public"]["Enums"]["operator_account_type"]
        }
        Relationships: [
          {
            foreignKeyName: "operator_accounts_deployment_id_fkey"
            columns: ["deployment_id"]
            isOneToOne: false
            referencedRelation: "deployments"
            referencedColumns: ["id"]
          },
        ]
      }
      operator_members: {
        Row: {
          driver_id: string
          operator_account_id: string
          role: string
          since: string
        }
        Insert: {
          driver_id: string
          operator_account_id: string
          role?: string
          since?: string
        }
        Update: {
          driver_id?: string
          operator_account_id?: string
          role?: string
          since?: string
        }
        Relationships: [
          {
            foreignKeyName: "operator_members_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "operator_members_operator_account_id_fkey"
            columns: ["operator_account_id"]
            isOneToOne: false
            referencedRelation: "operator_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      parks: {
        Row: {
          active: boolean
          city_id: string
          confidence_score: number
          created_at: string
          id: string
          location: unknown
          name: string
          name_aliases: string[]
          source_id: string
          updated_at: string
          verification_status: Database["public"]["Enums"]["graph_verification"]
          verified_at: string | null
          verified_by: string | null
        }
        Insert: {
          active?: boolean
          city_id: string
          confidence_score?: number
          created_at?: string
          id?: string
          location: unknown
          name: string
          name_aliases?: string[]
          source_id: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
          verified_at?: string | null
          verified_by?: string | null
        }
        Update: {
          active?: boolean
          city_id?: string
          confidence_score?: number
          created_at?: string
          id?: string
          location?: unknown
          name?: string
          name_aliases?: string[]
          source_id?: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
          verified_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "parks_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parks_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "data_sources"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parks_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount: number
          channel: string
          commission_amount: number
          confirmed_at: string | null
          created_at: string
          currency: string
          driver_amount: number
          driver_id: string
          expires_at: string | null
          fee_bearer: string
          id: string
          method: string
          payer_phone_e164: string | null
          provider: string
          provider_fee: number | null
          provider_reference: string
          receipt_token: string | null
          rider_id: string | null
          source: string
          status: string
          trip_id: string | null
        }
        Insert: {
          amount: number
          channel: string
          commission_amount: number
          confirmed_at?: string | null
          created_at?: string
          currency: string
          driver_amount: number
          driver_id: string
          expires_at?: string | null
          fee_bearer: string
          id?: string
          method: string
          payer_phone_e164?: string | null
          provider?: string
          provider_fee?: number | null
          provider_reference: string
          receipt_token?: string | null
          rider_id?: string | null
          source: string
          status: string
          trip_id?: string | null
        }
        Update: {
          amount?: number
          channel?: string
          commission_amount?: number
          confirmed_at?: string | null
          created_at?: string
          currency?: string
          driver_amount?: number
          driver_id?: string
          expires_at?: string | null
          fee_bearer?: string
          id?: string
          method?: string
          payer_phone_e164?: string | null
          provider?: string
          provider_fee?: number | null
          provider_reference?: string
          receipt_token?: string | null
          rider_id?: string | null
          source?: string
          status?: string
          trip_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payments_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      pending_ledger_adjustments: {
        Row: {
          amount: number
          approved_at: string | null
          approved_by: string | null
          created_at: string
          currency: string
          driver_id: string
          id: string
          ledger_entry_id: number | null
          memo: string
          requested_by: string
          status: Database["public"]["Enums"]["ledger_adjustment_status"]
        }
        Insert: {
          amount: number
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          currency: string
          driver_id: string
          id?: string
          ledger_entry_id?: number | null
          memo: string
          requested_by: string
          status?: Database["public"]["Enums"]["ledger_adjustment_status"]
        }
        Update: {
          amount?: number
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          currency?: string
          driver_id?: string
          id?: string
          ledger_entry_id?: number | null
          memo?: string
          requested_by?: string
          status?: Database["public"]["Enums"]["ledger_adjustment_status"]
        }
        Relationships: [
          {
            foreignKeyName: "pending_ledger_adjustments_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pending_ledger_adjustments_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pending_ledger_adjustments_ledger_entry_id_fkey"
            columns: ["ledger_entry_id"]
            isOneToOne: false
            referencedRelation: "driver_ledger_entries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pending_ledger_adjustments_requested_by_fkey"
            columns: ["requested_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      pickup_events: {
        Row: {
          author_id: string
          client_ref: string
          created_at: string
          ends_at: string
          id: string
          lat: number
          lng: number
          name: string
          starts_at: string
        }
        Insert: {
          author_id: string
          client_ref: string
          created_at?: string
          ends_at: string
          id?: string
          lat: number
          lng: number
          name: string
          starts_at: string
        }
        Update: {
          author_id?: string
          client_ref?: string
          created_at?: string
          ends_at?: string
          id?: string
          lat?: number
          lng?: number
          name?: string
          starts_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "pickup_events_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      placement_counters: {
        Row: {
          day: string
          impressions: number
          placement_id: string
          taps: number
        }
        Insert: {
          day: string
          impressions?: number
          placement_id: string
          taps?: number
        }
        Update: {
          day?: string
          impressions?: number
          placement_id?: string
          taps?: number
        }
        Relationships: [
          {
            foreignKeyName: "placement_counters_placement_id_fkey"
            columns: ["placement_id"]
            isOneToOne: false
            referencedRelation: "sponsored_placements"
            referencedColumns: ["id"]
          },
        ]
      }
      planner_queries: {
        Row: {
          candidate_count: number
          candidates: Json
          chosen_candidate_id: string | null
          city_id: string | null
          created_at: string
          degraded: boolean
          destination: unknown
          direct_count: number
          filters: Json
          id: string
          latency_ms: number | null
          origin: unknown
          rider_id: string | null
        }
        Insert: {
          candidate_count: number
          candidates?: Json
          chosen_candidate_id?: string | null
          city_id?: string | null
          created_at?: string
          degraded?: boolean
          destination: unknown
          direct_count: number
          filters?: Json
          id?: string
          latency_ms?: number | null
          origin: unknown
          rider_id?: string | null
        }
        Update: {
          candidate_count?: number
          candidates?: Json
          chosen_candidate_id?: string | null
          city_id?: string | null
          created_at?: string
          degraded?: boolean
          destination?: unknown
          direct_count?: number
          filters?: Json
          id?: string
          latency_ms?: number | null
          origin?: unknown
          rider_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "planner_queries_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "planner_queries_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
        ]
      }
      price_negotiation_rounds: {
        Row: {
          amount: number
          id: string
          negotiation_id: string
          proposed_at: string
          proposed_by: Database["public"]["Enums"]["actor_type"]
          responded_at: string | null
          response: string | null
          round_number: number
        }
        Insert: {
          amount: number
          id?: string
          negotiation_id: string
          proposed_at?: string
          proposed_by: Database["public"]["Enums"]["actor_type"]
          responded_at?: string | null
          response?: string | null
          round_number: number
        }
        Update: {
          amount?: number
          id?: string
          negotiation_id?: string
          proposed_at?: string
          proposed_by?: Database["public"]["Enums"]["actor_type"]
          responded_at?: string | null
          response?: string | null
          round_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "price_negotiation_rounds_negotiation_id_fkey"
            columns: ["negotiation_id"]
            isOneToOne: false
            referencedRelation: "price_negotiations"
            referencedColumns: ["id"]
          },
        ]
      }
      price_negotiations: {
        Row: {
          agreed_amount: number | null
          anchor_amount: number
          anchor_quote_id: string | null
          candidate_ref: Json
          context: Database["public"]["Enums"]["negotiation_context"]
          created_at: string
          currency: string
          driver_id: string
          eta_band: Database["public"]["Enums"]["eta_band"] | null
          expires_at: string
          id: string
          pickup_radius_m: number | null
          resolved_at: string | null
          resulting_trip_id: string | null
          rider_id: string
          round_cap: number
          round_timeout_s: number
          status: Database["public"]["Enums"]["negotiation_status"]
        }
        Insert: {
          agreed_amount?: number | null
          anchor_amount: number
          anchor_quote_id?: string | null
          candidate_ref: Json
          context: Database["public"]["Enums"]["negotiation_context"]
          created_at?: string
          currency: string
          driver_id: string
          eta_band?: Database["public"]["Enums"]["eta_band"] | null
          expires_at: string
          id?: string
          pickup_radius_m?: number | null
          resolved_at?: string | null
          resulting_trip_id?: string | null
          rider_id: string
          round_cap: number
          round_timeout_s: number
          status?: Database["public"]["Enums"]["negotiation_status"]
        }
        Update: {
          agreed_amount?: number | null
          anchor_amount?: number
          anchor_quote_id?: string | null
          candidate_ref?: Json
          context?: Database["public"]["Enums"]["negotiation_context"]
          created_at?: string
          currency?: string
          driver_id?: string
          eta_band?: Database["public"]["Enums"]["eta_band"] | null
          expires_at?: string
          id?: string
          pickup_radius_m?: number | null
          resolved_at?: string | null
          resulting_trip_id?: string | null
          rider_id?: string
          round_cap?: number
          round_timeout_s?: number
          status?: Database["public"]["Enums"]["negotiation_status"]
        }
        Relationships: [
          {
            foreignKeyName: "price_negotiations_anchor_quote_id_fkey"
            columns: ["anchor_quote_id"]
            isOneToOne: false
            referencedRelation: "fare_quotes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "price_negotiations_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "price_negotiations_resulting_trip_id_fkey"
            columns: ["resulting_trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "price_negotiations_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_path: string | null
          created_at: string
          display_name: string | null
          gender: string | null
          id: string
          locale: string
          phone_e164: string | null
          phone_reauth_at: string | null
          updated_at: string
        }
        Insert: {
          avatar_path?: string | null
          created_at?: string
          display_name?: string | null
          gender?: string | null
          id: string
          locale?: string
          phone_e164?: string | null
          phone_reauth_at?: string | null
          updated_at?: string
        }
        Update: {
          avatar_path?: string | null
          created_at?: string
          display_name?: string | null
          gender?: string | null
          id?: string
          locale?: string
          phone_e164?: string | null
          phone_reauth_at?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      qr_sticker_requests: {
        Row: {
          created_at: string
          driver_code: string
          driver_id: string
          id: string
          reason: string
          status: string
        }
        Insert: {
          created_at?: string
          driver_code: string
          driver_id: string
          id?: string
          reason: string
          status?: string
        }
        Update: {
          created_at?: string
          driver_code?: string
          driver_id?: string
          id?: string
          reason?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "qr_sticker_requests_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
        ]
      }
      ratings: {
        Row: {
          comment: string | null
          created_at: string
          id: string
          ratee_profile_id: string
          rater_profile_id: string
          rater_role: string
          score: number
          tags: string[]
          trip_id: string
        }
        Insert: {
          comment?: string | null
          created_at?: string
          id?: string
          ratee_profile_id: string
          rater_profile_id: string
          rater_role: string
          score: number
          tags?: string[]
          trip_id: string
        }
        Update: {
          comment?: string | null
          created_at?: string
          id?: string
          ratee_profile_id?: string
          rater_profile_id?: string
          rater_role?: string
          score?: number
          tags?: string[]
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ratings_ratee_profile_id_fkey"
            columns: ["ratee_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ratings_rater_profile_id_fkey"
            columns: ["rater_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ratings_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      ride_rule_presets: {
        Row: {
          active: boolean
          body: string | null
          created_at: string
          default_params: Json
          effect: string
          id: string
          sort_order: number
          target_scope: string
          title: string
        }
        Insert: {
          active?: boolean
          body?: string | null
          created_at?: string
          default_params?: Json
          effect: string
          id: string
          sort_order?: number
          target_scope: string
          title: string
        }
        Update: {
          active?: boolean
          body?: string | null
          created_at?: string
          default_params?: Json
          effect?: string
          id?: string
          sort_order?: number
          target_scope?: string
          title?: string
        }
        Relationships: []
      }
      rider_favourites: {
        Row: {
          created_at: string
          driver_id: string
          rider_id: string
        }
        Insert: {
          created_at?: string
          driver_id: string
          rider_id: string
        }
        Update: {
          created_at?: string
          driver_id?: string
          rider_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "rider_favourites_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rider_favourites_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      rider_guardian_prefs: {
        Row: {
          check_in_minutes: number | null
          enabled: boolean
          long_stop_minutes: number | null
          off_route_m: number | null
          profile_id: string
          safe_word: string | null
          updated_at: string
        }
        Insert: {
          check_in_minutes?: number | null
          enabled?: boolean
          long_stop_minutes?: number | null
          off_route_m?: number | null
          profile_id: string
          safe_word?: string | null
          updated_at?: string
        }
        Update: {
          check_in_minutes?: number | null
          enabled?: boolean
          long_stop_minutes?: number | null
          off_route_m?: number | null
          profile_id?: string
          safe_word?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "rider_guardian_prefs_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      rider_payment_methods: {
        Row: {
          authorization_code: string
          bank: string | null
          brand: string | null
          created_at: string
          exp_month: number | null
          exp_year: number | null
          id: string
          is_default: boolean
          last4: string | null
          provider: string
          rider_id: string
        }
        Insert: {
          authorization_code: string
          bank?: string | null
          brand?: string | null
          created_at?: string
          exp_month?: number | null
          exp_year?: number | null
          id?: string
          is_default?: boolean
          last4?: string | null
          provider?: string
          rider_id: string
        }
        Update: {
          authorization_code?: string
          bank?: string | null
          brand?: string | null
          created_at?: string
          exp_month?: number | null
          exp_year?: number | null
          id?: string
          is_default?: boolean
          last4?: string | null
          provider?: string
          rider_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "rider_payment_methods_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
        ]
      }
      riders: {
        Row: {
          account_trust_weight: number
          created_at: string
          home_city_id: string | null
          id: string
          saved_sort: string | null
          trip_count: number
          updated_at: string
          wayfinding_mode: string
          women_only_pref: boolean
        }
        Insert: {
          account_trust_weight?: number
          created_at?: string
          home_city_id?: string | null
          id: string
          saved_sort?: string | null
          trip_count?: number
          updated_at?: string
          wayfinding_mode?: string
          women_only_pref?: boolean
        }
        Update: {
          account_trust_weight?: number
          created_at?: string
          home_city_id?: string | null
          id?: string
          saved_sort?: string | null
          trip_count?: number
          updated_at?: string
          wayfinding_mode?: string
          women_only_pref?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "riders_home_city_id_fkey"
            columns: ["home_city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "riders_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      road_geometry_corrections: {
        Row: {
          city_id: string
          created_at: string
          geometry: unknown
          id: string
          osm_changeset_id: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          supporting_trace_count: number
        }
        Insert: {
          city_id: string
          created_at?: string
          geometry: unknown
          id?: string
          osm_changeset_id?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          supporting_trace_count: number
        }
        Update: {
          city_id?: string
          created_at?: string
          geometry?: unknown
          id?: string
          osm_changeset_id?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          supporting_trace_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "road_geometry_corrections_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "road_geometry_corrections_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      route_inference_candidates: {
        Row: {
          city_id: string
          created_at: string
          destination_cluster: unknown
          geometry: unknown
          id: string
          mode_code: string | null
          origin_cluster: unknown
          reviewed_at: string | null
          reviewed_by: string | null
          route_id: string | null
          status: string
          supporting_trip_count: number
        }
        Insert: {
          city_id: string
          created_at?: string
          destination_cluster?: unknown
          geometry: unknown
          id?: string
          mode_code?: string | null
          origin_cluster?: unknown
          reviewed_at?: string | null
          reviewed_by?: string | null
          route_id?: string | null
          status?: string
          supporting_trip_count: number
        }
        Update: {
          city_id?: string
          created_at?: string
          destination_cluster?: unknown
          geometry?: unknown
          id?: string
          mode_code?: string | null
          origin_cluster?: unknown
          reviewed_at?: string | null
          reviewed_by?: string | null
          route_id?: string | null
          status?: string
          supporting_trip_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "route_inference_candidates_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_inference_candidates_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "route_inference_candidates_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_inference_candidates_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
        ]
      }
      route_legs: {
        Row: {
          avg_wait_time_estimate_s: number | null
          boarding_walk_distance_m: number
          confidence_score: number
          created_at: string
          distance_m: number | null
          fare_amount: number
          fare_currency: string
          fare_last_verified_at: string | null
          frequency_estimate_per_hour: number | null
          from_stage_id: string
          id: string
          in_vehicle_time_estimate_s: number | null
          independent_confirmation_count: number
          mode_code: string
          operating_hours: Json | null
          route_id: string
          segment_keys: string[]
          source_id: string
          to_stage_id: string
          updated_at: string
          verification_status: Database["public"]["Enums"]["graph_verification"]
        }
        Insert: {
          avg_wait_time_estimate_s?: number | null
          boarding_walk_distance_m?: number
          confidence_score?: number
          created_at?: string
          distance_m?: number | null
          fare_amount: number
          fare_currency: string
          fare_last_verified_at?: string | null
          frequency_estimate_per_hour?: number | null
          from_stage_id: string
          id?: string
          in_vehicle_time_estimate_s?: number | null
          independent_confirmation_count?: number
          mode_code: string
          operating_hours?: Json | null
          route_id: string
          segment_keys?: string[]
          source_id: string
          to_stage_id: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
        }
        Update: {
          avg_wait_time_estimate_s?: number | null
          boarding_walk_distance_m?: number
          confidence_score?: number
          created_at?: string
          distance_m?: number | null
          fare_amount?: number
          fare_currency?: string
          fare_last_verified_at?: string | null
          frequency_estimate_per_hour?: number | null
          from_stage_id?: string
          id?: string
          in_vehicle_time_estimate_s?: number | null
          independent_confirmation_count?: number
          mode_code?: string
          operating_hours?: Json | null
          route_id?: string
          segment_keys?: string[]
          source_id?: string
          to_stage_id?: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
        }
        Relationships: [
          {
            foreignKeyName: "route_legs_from_stage_id_fkey"
            columns: ["from_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_legs_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "route_legs_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_legs_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "data_sources"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_legs_to_stage_id_fkey"
            columns: ["to_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
        ]
      }
      route_requests: {
        Row: {
          client_ref: string
          corridor_label: string
          created_at: string
          id: string
          rider_id: string
        }
        Insert: {
          client_ref: string
          corridor_label: string
          created_at?: string
          id?: string
          rider_id: string
        }
        Update: {
          client_ref?: string
          corridor_label?: string
          created_at?: string
          id?: string
          rider_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "route_requests_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      route_stages: {
        Row: {
          confidence_score: number
          created_at: string
          id: string
          independent_confirmation_count: number
          is_official_park: boolean
          location: unknown
          name: string | null
          park_id: string | null
          route_id: string
          sequence: number
          source_id: string
          updated_at: string
          verification_status: Database["public"]["Enums"]["graph_verification"]
        }
        Insert: {
          confidence_score?: number
          created_at?: string
          id?: string
          independent_confirmation_count?: number
          is_official_park?: boolean
          location: unknown
          name?: string | null
          park_id?: string | null
          route_id: string
          sequence: number
          source_id: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
        }
        Update: {
          confidence_score?: number
          created_at?: string
          id?: string
          independent_confirmation_count?: number
          is_official_park?: boolean
          location?: unknown
          name?: string | null
          park_id?: string | null
          route_id?: string
          sequence?: number
          source_id?: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
        }
        Relationships: [
          {
            foreignKeyName: "route_stages_park_id_fkey"
            columns: ["park_id"]
            isOneToOne: false
            referencedRelation: "parks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_stages_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_stages_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "data_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      route_through_fares: {
        Row: {
          confidence_score: number
          created_at: string
          fare_amount: number
          fare_currency: string
          fare_last_verified_at: string | null
          from_stage_id: string
          id: string
          independent_confirmation_count: number
          mode_code: string
          route_id: string
          source_id: string
          to_stage_id: string
          updated_at: string
          verification_status: Database["public"]["Enums"]["graph_verification"]
        }
        Insert: {
          confidence_score?: number
          created_at?: string
          fare_amount: number
          fare_currency: string
          fare_last_verified_at?: string | null
          from_stage_id: string
          id?: string
          independent_confirmation_count?: number
          mode_code: string
          route_id: string
          source_id: string
          to_stage_id: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
        }
        Update: {
          confidence_score?: number
          created_at?: string
          fare_amount?: number
          fare_currency?: string
          fare_last_verified_at?: string | null
          from_stage_id?: string
          id?: string
          independent_confirmation_count?: number
          mode_code?: string
          route_id?: string
          source_id?: string
          to_stage_id?: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
        }
        Relationships: [
          {
            foreignKeyName: "route_through_fares_from_stage_id_fkey"
            columns: ["from_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_through_fares_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "route_through_fares_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_through_fares_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "data_sources"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "route_through_fares_to_stage_id_fkey"
            columns: ["to_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
        ]
      }
      routes: {
        Row: {
          active: boolean
          city_id: string
          confidence_score: number
          corridor_id: string | null
          created_at: string
          destination_park_id: string
          id: string
          is_direct: boolean
          mode_code: string
          name: string | null
          origin_park_id: string
          path: unknown
          source_id: string
          updated_at: string
          verification_status: Database["public"]["Enums"]["graph_verification"]
        }
        Insert: {
          active?: boolean
          city_id: string
          confidence_score?: number
          corridor_id?: string | null
          created_at?: string
          destination_park_id: string
          id?: string
          is_direct?: boolean
          mode_code: string
          name?: string | null
          origin_park_id: string
          path?: unknown
          source_id: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
        }
        Update: {
          active?: boolean
          city_id?: string
          confidence_score?: number
          corridor_id?: string | null
          created_at?: string
          destination_park_id?: string
          id?: string
          is_direct?: boolean
          mode_code?: string
          name?: string | null
          origin_park_id?: string
          path?: unknown
          source_id?: string
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["graph_verification"]
        }
        Relationships: [
          {
            foreignKeyName: "routes_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "routes_corridor_id_fkey"
            columns: ["corridor_id"]
            isOneToOne: false
            referencedRelation: "corridors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "routes_destination_park_id_fkey"
            columns: ["destination_park_id"]
            isOneToOne: false
            referencedRelation: "parks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "routes_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "routes_origin_park_id_fkey"
            columns: ["origin_park_id"]
            isOneToOne: false
            referencedRelation: "parks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "routes_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "data_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      segment_speed_profiles: {
        Row: {
          city_id: string
          dow_bucket: number
          hour_bucket: number
          median_speed_mps: number
          p85_speed_mps: number | null
          sample_count: number
          segment_key: string
          updated_at: string
        }
        Insert: {
          city_id: string
          dow_bucket: number
          hour_bucket: number
          median_speed_mps: number
          p85_speed_mps?: number | null
          sample_count: number
          segment_key: string
          updated_at?: string
        }
        Update: {
          city_id?: string
          dow_bucket?: number
          hour_bucket?: number
          median_speed_mps?: number
          p85_speed_mps?: number | null
          sample_count?: number
          segment_key?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "segment_speed_profiles_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
        ]
      }
      settlement_agents: {
        Row: {
          active: boolean
          business_name: string
          city_id: string
          created_at: string
          id: string
          location: unknown
          profile_id: string
          updated_at: string
        }
        Insert: {
          active?: boolean
          business_name: string
          city_id: string
          created_at?: string
          id?: string
          location?: unknown
          profile_id: string
          updated_at?: string
        }
        Update: {
          active?: boolean
          business_name?: string
          city_id?: string
          created_at?: string
          id?: string
          location?: unknown
          profile_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "settlement_agents_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "settlement_agents_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      settlements: {
        Row: {
          agent_code: string | null
          agent_id: string | null
          amount: number
          channel: Database["public"]["Enums"]["settlement_channel"]
          confirmed_at: string | null
          created_at: string
          currency: string
          driver_id: string
          expires_at: string | null
          id: string
          ledger_entry_id: number | null
          provider_reference: string | null
          status: Database["public"]["Enums"]["settlement_status"]
        }
        Insert: {
          agent_code?: string | null
          agent_id?: string | null
          amount: number
          channel: Database["public"]["Enums"]["settlement_channel"]
          confirmed_at?: string | null
          created_at?: string
          currency: string
          driver_id: string
          expires_at?: string | null
          id?: string
          ledger_entry_id?: number | null
          provider_reference?: string | null
          status?: Database["public"]["Enums"]["settlement_status"]
        }
        Update: {
          agent_code?: string | null
          agent_id?: string | null
          amount?: number
          channel?: Database["public"]["Enums"]["settlement_channel"]
          confirmed_at?: string | null
          created_at?: string
          currency?: string
          driver_id?: string
          expires_at?: string | null
          id?: string
          ledger_entry_id?: number | null
          provider_reference?: string | null
          status?: Database["public"]["Enums"]["settlement_status"]
        }
        Relationships: [
          {
            foreignKeyName: "settlements_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "settlement_agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "settlements_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "settlements_ledger_entry_id_fkey"
            columns: ["ledger_entry_id"]
            isOneToOne: false
            referencedRelation: "driver_ledger_entries"
            referencedColumns: ["id"]
          },
        ]
      }
      sos_alerts: {
        Row: {
          accuracy_m: number | null
          acknowledged_at: string | null
          acknowledged_by: string | null
          created_at: string
          id: string
          journey_id: string | null
          location: unknown
          raised_by: string
          raised_role: string
          resolution_note: string | null
          resolved_at: string | null
          share_id: string | null
          status: Database["public"]["Enums"]["sos_status"]
          trip_id: string | null
        }
        Insert: {
          accuracy_m?: number | null
          acknowledged_at?: string | null
          acknowledged_by?: string | null
          created_at?: string
          id?: string
          journey_id?: string | null
          location: unknown
          raised_by: string
          raised_role: string
          resolution_note?: string | null
          resolved_at?: string | null
          share_id?: string | null
          status?: Database["public"]["Enums"]["sos_status"]
          trip_id?: string | null
        }
        Update: {
          accuracy_m?: number | null
          acknowledged_at?: string | null
          acknowledged_by?: string | null
          created_at?: string
          id?: string
          journey_id?: string | null
          location?: unknown
          raised_by?: string
          raised_role?: string
          resolution_note?: string | null
          resolved_at?: string | null
          share_id?: string | null
          status?: Database["public"]["Enums"]["sos_status"]
          trip_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "sos_alerts_acknowledged_by_fkey"
            columns: ["acknowledged_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sos_alerts_journey_id_fkey"
            columns: ["journey_id"]
            isOneToOne: false
            referencedRelation: "journeys"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sos_alerts_raised_by_fkey"
            columns: ["raised_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sos_alerts_share_id_fkey"
            columns: ["share_id"]
            isOneToOne: false
            referencedRelation: "trip_shares"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sos_alerts_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      spatial_ref_sys: {
        Row: {
          auth_name: string | null
          auth_srid: number | null
          proj4text: string | null
          srid: number
          srtext: string | null
        }
        Insert: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid: number
          srtext?: string | null
        }
        Update: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid?: number
          srtext?: string | null
        }
        Relationships: []
      }
      split_settlement_alerts: {
        Row: {
          created_at: string
          delta: number
          driver_id: string
          expected_driver_total: number
          id: string
          provider_reported_total: number
          reconciliation_day: string
          resolved_at: string | null
          status: string
          subaccount_code: string
        }
        Insert: {
          created_at?: string
          delta: number
          driver_id: string
          expected_driver_total: number
          id?: string
          provider_reported_total: number
          reconciliation_day: string
          resolved_at?: string | null
          status?: string
          subaccount_code: string
        }
        Update: {
          created_at?: string
          delta?: number
          driver_id?: string
          expected_driver_total?: number
          id?: string
          provider_reported_total?: number
          reconciliation_day?: string
          resolved_at?: string | null
          status?: string
          subaccount_code?: string
        }
        Relationships: [
          {
            foreignKeyName: "split_settlement_alerts_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
        ]
      }
      sponsored_placements: {
        Row: {
          active_from: string
          active_to: string
          advertiser: string
          content: Json
          context_type: Database["public"]["Enums"]["placement_context_type"]
          created_at: string
          deployment_id: string
          id: string
          target_reference: string
        }
        Insert: {
          active_from: string
          active_to: string
          advertiser: string
          content?: Json
          context_type: Database["public"]["Enums"]["placement_context_type"]
          created_at?: string
          deployment_id: string
          id?: string
          target_reference: string
        }
        Update: {
          active_from?: string
          active_to?: string
          advertiser?: string
          content?: Json
          context_type?: Database["public"]["Enums"]["placement_context_type"]
          created_at?: string
          deployment_id?: string
          id?: string
          target_reference?: string
        }
        Relationships: [
          {
            foreignKeyName: "sponsored_placements_deployment_id_fkey"
            columns: ["deployment_id"]
            isOneToOne: false
            referencedRelation: "deployments"
            referencedColumns: ["id"]
          },
        ]
      }
      stage_dwell_samples: {
        Row: {
          city_id: string
          dwell_s: number
          hour_bucket: number
          id: string
          observed_at: string
          stage_id: string
          trip_id: string | null
        }
        Insert: {
          city_id: string
          dwell_s: number
          hour_bucket: number
          id?: string
          observed_at?: string
          stage_id: string
          trip_id?: string | null
        }
        Update: {
          city_id?: string
          dwell_s?: number
          hour_bucket?: number
          id?: string
          observed_at?: string
          stage_id?: string
          trip_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "stage_dwell_samples_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stage_dwell_samples_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stage_dwell_samples_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      transfer_points: {
        Row: {
          park_id: string
          route_id: string
          stage_id: string
          transfer_time_s: number
          walk_distance_m: number
        }
        Insert: {
          park_id: string
          route_id: string
          stage_id: string
          transfer_time_s?: number
          walk_distance_m?: number
        }
        Update: {
          park_id?: string
          route_id?: string
          stage_id?: string
          transfer_time_s?: number
          walk_distance_m?: number
        }
        Relationships: [
          {
            foreignKeyName: "transfer_points_park_id_fkey"
            columns: ["park_id"]
            isOneToOne: false
            referencedRelation: "parks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transfer_points_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transfer_points_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
        ]
      }
      trip_dispatch_context: {
        Row: {
          ambient_cell: string
          created_at: string
          destination: unknown
          hail_source: string
          mode_code: string
          origin: unknown
          tried_driver_ids: string[]
          trip_id: string
        }
        Insert: {
          ambient_cell: string
          created_at?: string
          destination: unknown
          hail_source?: string
          mode_code: string
          origin: unknown
          tried_driver_ids?: string[]
          trip_id: string
        }
        Update: {
          ambient_cell?: string
          created_at?: string
          destination?: unknown
          hail_source?: string
          mode_code?: string
          origin?: unknown
          tried_driver_ids?: string[]
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "trip_dispatch_context_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "trip_dispatch_context_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: true
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      trip_events: {
        Row: {
          actor_id: string | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          created_at: string
          from_status: Database["public"]["Enums"]["trip_status"] | null
          id: number
          meta: Json | null
          reason: string | null
          to_status: Database["public"]["Enums"]["trip_status"]
          trip_id: string
        }
        Insert: {
          actor_id?: string | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          created_at?: string
          from_status?: Database["public"]["Enums"]["trip_status"] | null
          id?: number
          meta?: Json | null
          reason?: string | null
          to_status: Database["public"]["Enums"]["trip_status"]
          trip_id: string
        }
        Update: {
          actor_id?: string | null
          actor_type?: Database["public"]["Enums"]["actor_type"]
          created_at?: string
          from_status?: Database["public"]["Enums"]["trip_status"] | null
          id?: number
          meta?: Json | null
          reason?: string | null
          to_status?: Database["public"]["Enums"]["trip_status"]
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "trip_events_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      trip_extensions: {
        Row: {
          commission_delta: number | null
          currency: string
          expires_at: string
          fare_delta: number
          fare_quote_id: string | null
          id: string
          ledger_entry_id: number | null
          new_alighting_location: unknown
          new_alighting_stage_id: string | null
          previous_alighting_location: unknown
          previous_alighting_stage_id: string | null
          proposed_at: string
          proposed_by: Database["public"]["Enums"]["actor_type"]
          responded_at: string | null
          status: string
          trip_id: string
        }
        Insert: {
          commission_delta?: number | null
          currency: string
          expires_at: string
          fare_delta: number
          fare_quote_id?: string | null
          id?: string
          ledger_entry_id?: number | null
          new_alighting_location?: unknown
          new_alighting_stage_id?: string | null
          previous_alighting_location?: unknown
          previous_alighting_stage_id?: string | null
          proposed_at?: string
          proposed_by: Database["public"]["Enums"]["actor_type"]
          responded_at?: string | null
          status?: string
          trip_id: string
        }
        Update: {
          commission_delta?: number | null
          currency?: string
          expires_at?: string
          fare_delta?: number
          fare_quote_id?: string | null
          id?: string
          ledger_entry_id?: number | null
          new_alighting_location?: unknown
          new_alighting_stage_id?: string | null
          previous_alighting_location?: unknown
          previous_alighting_stage_id?: string | null
          proposed_at?: string
          proposed_by?: Database["public"]["Enums"]["actor_type"]
          responded_at?: string | null
          status?: string
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "te_ledger_fk"
            columns: ["ledger_entry_id"]
            isOneToOne: false
            referencedRelation: "driver_ledger_entries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_extensions_fare_quote_id_fkey"
            columns: ["fare_quote_id"]
            isOneToOne: false
            referencedRelation: "fare_quotes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_extensions_new_alighting_stage_id_fkey"
            columns: ["new_alighting_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_extensions_previous_alighting_stage_id_fkey"
            columns: ["previous_alighting_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_extensions_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      trip_handshakes: {
        Row: {
          attempts: number
          created_at: string
          last_attempt_at: string | null
          matched_at: string | null
          matched_method: string | null
          secret: string
          tap_locked: boolean
          trip_id: string
        }
        Insert: {
          attempts?: number
          created_at?: string
          last_attempt_at?: string | null
          matched_at?: string | null
          matched_method?: string | null
          secret?: string
          tap_locked?: boolean
          trip_id: string
        }
        Update: {
          attempts?: number
          created_at?: string
          last_attempt_at?: string | null
          matched_at?: string | null
          matched_method?: string | null
          secret?: string
          tap_locked?: boolean
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "trip_handshakes_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: true
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      trip_location_samples: {
        Row: {
          accuracy_m: number | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          heading: number | null
          id: number
          location: unknown
          speed_mps: number | null
          trip_id: string
          ts: string
        }
        Insert: {
          accuracy_m?: number | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          heading?: number | null
          id?: number
          location: unknown
          speed_mps?: number | null
          trip_id: string
          ts: string
        }
        Update: {
          accuracy_m?: number | null
          actor_type?: Database["public"]["Enums"]["actor_type"]
          heading?: number | null
          id?: number
          location?: unknown
          speed_mps?: number | null
          trip_id?: string
          ts?: string
        }
        Relationships: []
      }
      trip_location_samples_y2026_m10: {
        Row: {
          accuracy_m: number | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          heading: number | null
          id: number
          location: unknown
          speed_mps: number | null
          trip_id: string
          ts: string
        }
        Insert: {
          accuracy_m?: number | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          heading?: number | null
          id?: number
          location: unknown
          speed_mps?: number | null
          trip_id: string
          ts: string
        }
        Update: {
          accuracy_m?: number | null
          actor_type?: Database["public"]["Enums"]["actor_type"]
          heading?: number | null
          id?: number
          location?: unknown
          speed_mps?: number | null
          trip_id?: string
          ts?: string
        }
        Relationships: []
      }
      trip_location_samples_y2026_m11: {
        Row: {
          accuracy_m: number | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          heading: number | null
          id: number
          location: unknown
          speed_mps: number | null
          trip_id: string
          ts: string
        }
        Insert: {
          accuracy_m?: number | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          heading?: number | null
          id?: number
          location: unknown
          speed_mps?: number | null
          trip_id: string
          ts: string
        }
        Update: {
          accuracy_m?: number | null
          actor_type?: Database["public"]["Enums"]["actor_type"]
          heading?: number | null
          id?: number
          location?: unknown
          speed_mps?: number | null
          trip_id?: string
          ts?: string
        }
        Relationships: []
      }
      trip_location_samples_y2026_m12: {
        Row: {
          accuracy_m: number | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          heading: number | null
          id: number
          location: unknown
          speed_mps: number | null
          trip_id: string
          ts: string
        }
        Insert: {
          accuracy_m?: number | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          heading?: number | null
          id?: number
          location: unknown
          speed_mps?: number | null
          trip_id: string
          ts: string
        }
        Update: {
          accuracy_m?: number | null
          actor_type?: Database["public"]["Enums"]["actor_type"]
          heading?: number | null
          id?: number
          location?: unknown
          speed_mps?: number | null
          trip_id?: string
          ts?: string
        }
        Relationships: []
      }
      trip_messages: {
        Row: {
          author_id: string
          author_role: string
          body: string
          client_ref: string
          created_at: string
          id: string
          read_at: string | null
          thread: string
          trip_id: string
        }
        Insert: {
          author_id: string
          author_role: string
          body: string
          client_ref: string
          created_at?: string
          id?: string
          read_at?: string | null
          thread?: string
          trip_id: string
        }
        Update: {
          author_id?: string
          author_role?: string
          body?: string
          client_ref?: string
          created_at?: string
          id?: string
          read_at?: string | null
          thread?: string
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "trip_messages_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_messages_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      trip_pins: {
        Row: {
          attempts: number
          created_at: string
          last_attempt_at: string | null
          pin: string
          regenerated_at: string | null
          regenerations: number
          trip_id: string
          verified_at: string | null
          verified_by: Database["public"]["Enums"]["actor_type"] | null
        }
        Insert: {
          attempts?: number
          created_at?: string
          last_attempt_at?: string | null
          pin: string
          regenerated_at?: string | null
          regenerations?: number
          trip_id: string
          verified_at?: string | null
          verified_by?: Database["public"]["Enums"]["actor_type"] | null
        }
        Update: {
          attempts?: number
          created_at?: string
          last_attempt_at?: string | null
          pin?: string
          regenerated_at?: string | null
          regenerations?: number
          trip_id?: string
          verified_at?: string | null
          verified_by?: Database["public"]["Enums"]["actor_type"] | null
        }
        Relationships: [
          {
            foreignKeyName: "trip_pins_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: true
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      trip_reconciliation_flags: {
        Row: {
          corroborating_rider_count: number
          created_at: string
          driver_id: string
          evidence: Json
          flag_type: Database["public"]["Enums"]["flag_type"]
          id: string
          review_note: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          rider_trace_quality: Database["public"]["Enums"]["trace_quality"]
          score: number
          standing_transition_id: number | null
          status: Database["public"]["Enums"]["flag_status"]
          trip_id: string
        }
        Insert: {
          corroborating_rider_count?: number
          created_at?: string
          driver_id: string
          evidence: Json
          flag_type: Database["public"]["Enums"]["flag_type"]
          id?: string
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          rider_trace_quality: Database["public"]["Enums"]["trace_quality"]
          score: number
          standing_transition_id?: number | null
          status?: Database["public"]["Enums"]["flag_status"]
          trip_id: string
        }
        Update: {
          corroborating_rider_count?: number
          created_at?: string
          driver_id?: string
          evidence?: Json
          flag_type?: Database["public"]["Enums"]["flag_type"]
          id?: string
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          rider_trace_quality?: Database["public"]["Enums"]["trace_quality"]
          score?: number
          standing_transition_id?: number | null
          status?: Database["public"]["Enums"]["flag_status"]
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "trip_reconciliation_flags_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_reconciliation_flags_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_reconciliation_flags_standing_transition_id_fkey"
            columns: ["standing_transition_id"]
            isOneToOne: false
            referencedRelation: "driver_standing_transitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_reconciliation_flags_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      trip_shares: {
        Row: {
          contact_name: string | null
          contact_phone_e164: string | null
          created_at: string
          expires_at: string
          id: string
          journey_id: string
          revoked_at: string | null
          rider_id: string
          token_hash: string
        }
        Insert: {
          contact_name?: string | null
          contact_phone_e164?: string | null
          created_at?: string
          expires_at: string
          id?: string
          journey_id: string
          revoked_at?: string | null
          rider_id: string
          token_hash: string
        }
        Update: {
          contact_name?: string | null
          contact_phone_e164?: string | null
          created_at?: string
          expires_at?: string
          id?: string
          journey_id?: string
          revoked_at?: string | null
          rider_id?: string
          token_hash?: string
        }
        Relationships: [
          {
            foreignKeyName: "trip_shares_journey_id_fkey"
            columns: ["journey_id"]
            isOneToOne: false
            referencedRelation: "journeys"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_shares_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
        ]
      }
      trips: {
        Row: {
          accepted_at: string | null
          alighting_location: unknown
          alighting_stage_id: string | null
          boarded_at: string | null
          boarded_via: string | null
          boarding_location: unknown
          boarding_stage_id: string | null
          cancel_reason: string | null
          cancelled_at: string | null
          commission_amount: number | null
          commission_rate: number
          created_at: string
          decline_reason: string | null
          dispatch_attempt: number
          driver_id: string | null
          driver_live_path: unknown
          driver_route_profile_id: string | null
          ended_at: string | null
          expires_at: string
          fare_currency: string
          fare_quote_id: string
          fare_reported_paid: number | null
          fare_shown: number
          fare_tier: number
          id: string
          id_signal_color: string
          id_signal_shape: string
          journey_id: string
          journey_sequence: number
          load_flagged: boolean
          load_note: string | null
          load_size: Database["public"]["Enums"]["load_size"] | null
          load_surcharge_amount: number
          meta: Json
          mode_code: string
          payment_method: Database["public"]["Enums"]["payment_method"]
          requested_at: string
          rider_id: string
          rider_live_path: unknown
          route_id: string | null
          route_leg_ids: string[]
          started_at: string | null
          status: Database["public"]["Enums"]["trip_status"]
          updated_at: string
          vehicle_id: string | null
          women_only: boolean
        }
        Insert: {
          accepted_at?: string | null
          alighting_location?: unknown
          alighting_stage_id?: string | null
          boarded_at?: string | null
          boarded_via?: string | null
          boarding_location?: unknown
          boarding_stage_id?: string | null
          cancel_reason?: string | null
          cancelled_at?: string | null
          commission_amount?: number | null
          commission_rate: number
          created_at?: string
          decline_reason?: string | null
          dispatch_attempt?: number
          driver_id?: string | null
          driver_live_path?: unknown
          driver_route_profile_id?: string | null
          ended_at?: string | null
          expires_at: string
          fare_currency: string
          fare_quote_id: string
          fare_reported_paid?: number | null
          fare_shown: number
          fare_tier: number
          id?: string
          id_signal_color: string
          id_signal_shape: string
          journey_id: string
          journey_sequence?: number
          load_flagged?: boolean
          load_note?: string | null
          load_size?: Database["public"]["Enums"]["load_size"] | null
          load_surcharge_amount?: number
          meta?: Json
          mode_code: string
          payment_method?: Database["public"]["Enums"]["payment_method"]
          requested_at?: string
          rider_id: string
          rider_live_path?: unknown
          route_id?: string | null
          route_leg_ids?: string[]
          started_at?: string | null
          status?: Database["public"]["Enums"]["trip_status"]
          updated_at?: string
          vehicle_id?: string | null
          women_only?: boolean
        }
        Update: {
          accepted_at?: string | null
          alighting_location?: unknown
          alighting_stage_id?: string | null
          boarded_at?: string | null
          boarded_via?: string | null
          boarding_location?: unknown
          boarding_stage_id?: string | null
          cancel_reason?: string | null
          cancelled_at?: string | null
          commission_amount?: number | null
          commission_rate?: number
          created_at?: string
          decline_reason?: string | null
          dispatch_attempt?: number
          driver_id?: string | null
          driver_live_path?: unknown
          driver_route_profile_id?: string | null
          ended_at?: string | null
          expires_at?: string
          fare_currency?: string
          fare_quote_id?: string
          fare_reported_paid?: number | null
          fare_shown?: number
          fare_tier?: number
          id?: string
          id_signal_color?: string
          id_signal_shape?: string
          journey_id?: string
          journey_sequence?: number
          load_flagged?: boolean
          load_note?: string | null
          load_size?: Database["public"]["Enums"]["load_size"] | null
          load_surcharge_amount?: number
          meta?: Json
          mode_code?: string
          payment_method?: Database["public"]["Enums"]["payment_method"]
          requested_at?: string
          rider_id?: string
          rider_live_path?: unknown
          route_id?: string | null
          route_leg_ids?: string[]
          started_at?: string | null
          status?: Database["public"]["Enums"]["trip_status"]
          updated_at?: string
          vehicle_id?: string | null
          women_only?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "trips_alighting_stage_id_fkey"
            columns: ["alighting_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trips_boarding_stage_id_fkey"
            columns: ["boarding_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trips_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trips_driver_route_profile_id_fkey"
            columns: ["driver_route_profile_id"]
            isOneToOne: false
            referencedRelation: "driver_route_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trips_fare_quote_id_fkey"
            columns: ["fare_quote_id"]
            isOneToOne: false
            referencedRelation: "fare_quotes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trips_journey_id_fkey"
            columns: ["journey_id"]
            isOneToOne: false
            referencedRelation: "journeys"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trips_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "trips_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trips_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trips_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      vehicle_layouts: {
        Row: {
          created_at: string
          driver_id: string
          id: string
          is_active: boolean
          layout: Json
          name: string
          over_capacity: boolean
          passenger_seats: number
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          created_at?: string
          driver_id: string
          id?: string
          is_active?: boolean
          layout: Json
          name: string
          over_capacity?: boolean
          passenger_seats: number
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          created_at?: string
          driver_id?: string
          id?: string
          is_active?: boolean
          layout?: Json
          name?: string
          over_capacity?: boolean
          passenger_seats?: number
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vehicle_layouts_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vehicle_layouts_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      vehicle_seat_states: {
        Row: {
          hold_until: string | null
          holder_profile_id: string | null
          layout_id: string
          seat_id: string
          status: string
          updated_at: string
          version: number
        }
        Insert: {
          hold_until?: string | null
          holder_profile_id?: string | null
          layout_id: string
          seat_id: string
          status?: string
          updated_at?: string
          version?: number
        }
        Update: {
          hold_until?: string | null
          holder_profile_id?: string | null
          layout_id?: string
          seat_id?: string
          status?: string
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "vehicle_seat_states_holder_profile_id_fkey"
            columns: ["holder_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vehicle_seat_states_layout_id_fkey"
            columns: ["layout_id"]
            isOneToOne: false
            referencedRelation: "vehicle_layouts"
            referencedColumns: ["id"]
          },
        ]
      }
      vehicles: {
        Row: {
          color: string | null
          country_code: string
          created_at: string
          id: string
          make_model: string | null
          mode_code: string
          owner_name: string | null
          owner_phone_e164: string | null
          owner_profile_id: string | null
          plate_normalized: string | null
          plate_number: string
          seat_capacity: number
          updated_at: string
          verification_status: Database["public"]["Enums"]["verified_status"]
        }
        Insert: {
          color?: string | null
          country_code: string
          created_at?: string
          id?: string
          make_model?: string | null
          mode_code: string
          owner_name?: string | null
          owner_phone_e164?: string | null
          owner_profile_id?: string | null
          plate_normalized?: string | null
          plate_number: string
          seat_capacity: number
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["verified_status"]
        }
        Update: {
          color?: string | null
          country_code?: string
          created_at?: string
          id?: string
          make_model?: string | null
          mode_code?: string
          owner_name?: string | null
          owner_phone_e164?: string | null
          owner_profile_id?: string | null
          plate_normalized?: string | null
          plate_number?: string
          seat_capacity?: number
          updated_at?: string
          verification_status?: Database["public"]["Enums"]["verified_status"]
        }
        Relationships: [
          {
            foreignKeyName: "vehicles_country_code_fkey"
            columns: ["country_code"]
            isOneToOne: false
            referencedRelation: "countries"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "vehicles_mode_code_fkey"
            columns: ["mode_code"]
            isOneToOne: false
            referencedRelation: "mode_config"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "vehicles_owner_profile_id_fkey"
            columns: ["owner_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      wallet_accounts: {
        Row: {
          balance: number
          created_at: string
          currency: string
          id: string
          kind: string
          owner_id: string | null
        }
        Insert: {
          balance?: number
          created_at?: string
          currency?: string
          id?: string
          kind: string
          owner_id?: string | null
        }
        Update: {
          balance?: number
          created_at?: string
          currency?: string
          id?: string
          kind?: string
          owner_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "wallet_accounts_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      wallet_entries: {
        Row: {
          account_id: string
          amount: number
          created_at: string
          id: string
          transaction_id: string
        }
        Insert: {
          account_id: string
          amount: number
          created_at?: string
          id?: string
          transaction_id: string
        }
        Update: {
          account_id?: string
          amount?: number
          created_at?: string
          id?: string
          transaction_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "wallet_entries_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "wallet_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wallet_entries_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "wallet_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      wallet_splits: {
        Row: {
          amount: number
          created_at: string
          id: string
          payer_id: string
          request_key: string
          requester_id: string
          settled_at: string | null
          status: string
          transaction_id: string | null
          trip_id: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          payer_id: string
          request_key: string
          requester_id: string
          settled_at?: string | null
          status?: string
          transaction_id?: string | null
          trip_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          payer_id?: string
          request_key?: string
          requester_id?: string
          settled_at?: string | null
          status?: string
          transaction_id?: string | null
          trip_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "wallet_splits_payer_id_fkey"
            columns: ["payer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wallet_splits_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wallet_splits_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "wallet_transactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wallet_splits_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      wallet_transactions: {
        Row: {
          created_at: string
          id: string
          idempotency_key: string
          initiator_id: string
          kind: string
          memo: Json
        }
        Insert: {
          created_at?: string
          id?: string
          idempotency_key: string
          initiator_id: string
          kind: string
          memo?: Json
        }
        Update: {
          created_at?: string
          id?: string
          idempotency_key?: string
          initiator_id?: string
          kind?: string
          memo?: Json
        }
        Relationships: [
          {
            foreignKeyName: "wallet_transactions_initiator_id_fkey"
            columns: ["initiator_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      driver_balances: {
        Row: {
          as_of: string | null
          balance: number | null
          currency: string | null
          driver_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "driver_ledger_entries_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_route_stop_location: {
        Row: {
          currency: string | null
          custom_label: string | null
          id: string | null
          location: unknown
          price_to_end: number | null
          profile_id: string | null
          route_stage_id: string | null
          sequence: number | null
        }
        Relationships: [
          {
            foreignKeyName: "driver_route_stops_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "driver_route_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_route_stops_route_stage_id_fkey"
            columns: ["route_stage_id"]
            isOneToOne: false
            referencedRelation: "route_stages"
            referencedColumns: ["id"]
          },
        ]
      }
      geography_columns: {
        Row: {
          coord_dimension: number | null
          f_geography_column: unknown
          f_table_catalog: unknown
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Relationships: []
      }
      geometry_columns: {
        Row: {
          coord_dimension: number | null
          f_geometry_column: unknown
          f_table_catalog: string | null
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Insert: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Update: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Relationships: []
      }
      my_verifications_v: {
        Row: {
          document_type: string | null
          rejection_reason: string | null
          status: Database["public"]["Enums"]["doc_status"] | null
          submitted_at: string | null
        }
        Insert: {
          document_type?: string | null
          rejection_reason?: string | null
          status?: Database["public"]["Enums"]["doc_status"] | null
          submitted_at?: string | null
        }
        Update: {
          document_type?: string | null
          rejection_reason?: string | null
          status?: Database["public"]["Enums"]["doc_status"] | null
          submitted_at?: string | null
        }
        Relationships: []
      }
      pg_all_foreign_keys: {
        Row: {
          fk_columns: unknown[] | null
          fk_constraint_name: unknown
          fk_schema_name: unknown
          fk_table_name: unknown
          fk_table_oid: unknown
          is_deferrable: boolean | null
          is_deferred: boolean | null
          match_type: string | null
          on_delete: string | null
          on_update: string | null
          pk_columns: unknown[] | null
          pk_constraint_name: unknown
          pk_index_name: unknown
          pk_schema_name: unknown
          pk_table_name: unknown
          pk_table_oid: unknown
        }
        Relationships: []
      }
      rider_payment_methods_safe: {
        Row: {
          bank: string | null
          brand: string | null
          created_at: string | null
          exp_month: number | null
          exp_year: number | null
          id: string | null
          is_default: boolean | null
          last4: string | null
          provider: string | null
          rider_id: string | null
        }
        Insert: {
          bank?: string | null
          brand?: string | null
          created_at?: string | null
          exp_month?: number | null
          exp_year?: number | null
          id?: string | null
          is_default?: boolean | null
          last4?: string | null
          provider?: string | null
          rider_id?: string | null
        }
        Update: {
          bank?: string | null
          brand?: string | null
          created_at?: string | null
          exp_month?: number | null
          exp_year?: number | null
          id?: string | null
          is_default?: boolean | null
          last4?: string | null
          provider?: string | null
          rider_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "rider_payment_methods_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
        ]
      }
      tap_funky: {
        Row: {
          args: string | null
          is_definer: boolean | null
          is_strict: boolean | null
          is_visible: boolean | null
          kind: unknown
          langoid: unknown
          name: unknown
          oid: unknown
          owner: unknown
          returns: string | null
          returns_set: boolean | null
          schema: unknown
          volatility: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      _admin_graph_source: { Args: { p_note: string }; Returns: string }
      _advance_journey_on_trip_complete: {
        Args: { p_trip: Database["public"]["Tables"]["trips"]["Row"] }
        Returns: undefined
      }
      _assert_driver_women_only_eligible: {
        Args: { p_driver_id: string; p_women_only: boolean }
        Returns: undefined
      }
      _assert_women_only_regulatory: {
        Args: { p_city_id: string; p_women_only: boolean }
        Returns: undefined
      }
      _auto_in_transit_check_core: {
        Args: { p_trip_id: string }
        Returns: boolean
      }
      _build_itinerary_prepared_plan: {
        Args: {
          p_city_id: string
          p_dest_lat: number
          p_dest_lng: number
          p_filters?: Json
          p_origin_lat: number
          p_origin_lng: number
          p_rider_id: string
        }
        Returns: Json
      }
      _build_trip_view_core: {
        Args: { p_trip_id: string; p_viewer_id?: string }
        Returns: Json
      }
      _candidate_token_payload: {
        Args: { p_driver_id: string; p_exp: number; p_session_id: string }
        Returns: string
      }
      _cleanup: { Args: never; Returns: boolean }
      _contract_on: { Args: { "": string }; Returns: unknown }
      _corridor_import_apply: {
        Args: { p_city_id: string; p_diff: Json }
        Returns: Json
      }
      _corridor_import_dry_run: {
        Args: { p_bundle: Json; p_city_id: string }
        Returns: Json
      }
      _corridor_route_label: {
        Args: {
          p_destination: string
          p_mode: string
          p_name: string
          p_origin: string
        }
        Returns: string
      }
      _currtest: { Args: never; Returns: number }
      _db_privs: { Args: never; Returns: unknown[] }
      _driver_declared_source: {
        Args: { p_driver_id: string }
        Returns: string
      }
      _eta_blend: {
        Args: {
          p_baseline: number
          p_live_median: number
          p_live_samples: number
          p_osrm_degraded: boolean
          p_planned: number
          p_profile_median: number
          p_profile_p85: number
          p_profile_samples: number
        }
        Returns: Json
      }
      _eta_dwell_s: {
        Args: { p_default: number; p_hour: number; p_stage_id: string }
        Returns: number
      }
      _eta_format: { Args: { p_high: number; p_low: number }; Returns: Json }
      _eta_lagos_clock: { Args: { p_at: string }; Returns: string }
      _eta_live_median: {
        Args: { p_at: string; p_keys: string[] }
        Returns: {
          median_mps: number
          samples: number
        }[]
      }
      _eta_minute: { Args: { p_seconds: number }; Returns: number }
      _eta_record_speeds: {
        Args: { p_points: Json; p_trip_id: string }
        Returns: undefined
      }
      _eta_scaled: {
        Args: { p_baseline: number; p_planned: number; p_speed: number }
        Returns: number
      }
      _eta_segment_estimate: {
        Args: {
          p_at: string
          p_baseline: number
          p_city: string
          p_degraded: boolean
          p_dow: number
          p_hour: number
          p_keys: string[]
          p_planned: number
        }
        Returns: Json
      }
      _eta_smooth: {
        Args: {
          p_live_speed: number
          p_previous: Json
          p_raw_high: number
          p_raw_low: number
        }
        Returns: Json
      }
      _extension_parse_endpoint: {
        Args: { p_value: Json }
        Returns: {
          point: unknown
          stage_id: string
        }[]
      }
      _extension_trip_actor: {
        Args: { p_trip_id: string; p_uid: string }
        Returns: Database["public"]["Enums"]["actor_type"]
      }
      _extensions: { Args: never; Returns: unknown[] }
      _fare_correction_resolve_target: {
        Args: { p_fc: Database["public"]["Tables"]["fare_corrections"]["Row"] }
        Returns: {
          target_id: string
          target_type: string
        }[]
      }
      _field_payload_point: { Args: { p_payload: Json }; Returns: unknown }
      _find_plan_leg: {
        Args: {
          p_candidate_id: string
          p_leg_index: number
          p_rider_id: string
        }
        Returns: Record<string, unknown>
      }
      _geo_point_json: { Args: { p_point: unknown }; Returns: Json }
      _get: { Args: { "": string }; Returns: number }
      _get_latest: { Args: { "": string }; Returns: number[] }
      _get_note: { Args: { "": string }; Returns: string }
      _graph_revision_target_table: {
        Args: { p_type: string }
        Returns: string
      }
      _intelligence_source: {
        Args: {
          p_job_run_id?: string
          p_note?: string
          p_source_type: Database["public"]["Enums"]["source_type"]
        }
        Returns: string
      }
      _is_verbose: { Args: never; Returns: boolean }
      _itinerary_next_pending_stop: {
        Args: { p_after_sequence?: number; p_itinerary_id: string }
        Returns: {
          created_at: string
          destination_description: string
          destination_location: unknown
          id: string
          itinerary_id: string
          linked_journey_id: string | null
          prepared_plan: Json | null
          sequence: number
          status: Database["public"]["Enums"]["stop_status"]
          target_time: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "itinerary_stops"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      _itinerary_origin_for_stop: {
        Args: {
          p_itinerary_id: string
          p_stop: Database["public"]["Tables"]["itinerary_stops"]["Row"]
        }
        Returns: unknown
      }
      _itinerary_state_json: { Args: { p_itinerary_id: string }; Returns: Json }
      _itinerary_stop_row_json: {
        Args: { p_stop: Database["public"]["Tables"]["itinerary_stops"]["Row"] }
        Returns: Json
      }
      _journey_plan_leg: {
        Args: { p_journey_id: string; p_leg_index: number }
        Returns: Json
      }
      _journey_planned_leg_count: {
        Args: { p_journey_id: string }
        Returns: number
      }
      _latest_trip_sample: {
        Args: {
          p_actor_type: Database["public"]["Enums"]["actor_type"]
          p_trip_id: string
        }
        Returns: {
          accuracy_m: number | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          heading: number | null
          id: number
          location: unknown
          speed_mps: number | null
          trip_id: string
          ts: string
        }
        SetofOptions: {
          from: "*"
          to: "trip_location_samples"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      _materialize_trip_paths: {
        Args: { p_trip_id: string }
        Returns: undefined
      }
      _mint_trip_pin: { Args: never; Returns: string }
      _mode_ref: { Args: { p_mode_code: string }; Returns: Json }
      _na_me_label: {
        Args: { p_color_token: string; p_locale?: string; p_shape: string }
        Returns: string
      }
      _na_me_optical_code: {
        Args: { p_secret: string; p_step: number }
        Returns: number
      }
      _na_me_pairs_in_use: {
        Args: { p_t: Database["public"]["Tables"]["trips"]["Row"] }
        Returns: string[]
      }
      _na_me_scope_matches: {
        Args: {
          a: Database["public"]["Tables"]["trips"]["Row"]
          b: Database["public"]["Tables"]["trips"]["Row"]
        }
        Returns: boolean
      }
      _na_me_token_label: { Args: { p_token: string }; Returns: string }
      _negotiation_actor_role: {
        Args: { p_negotiation_id: string; p_user_id: string }
        Returns: Database["public"]["Enums"]["actor_type"]
      }
      _negotiation_build_view: {
        Args: { p_negotiation_id: string }
        Returns: Json
      }
      _negotiation_chip_steps: {
        Args: { p_city_id: string }
        Returns: number[]
      }
      _negotiation_create_trip: {
        Args: {
          p_acceptor: Database["public"]["Enums"]["actor_type"]
          p_agreed_amount: number
          p_negotiation: Database["public"]["Tables"]["price_negotiations"]["Row"]
          p_quote_id: string
        }
        Returns: string
      }
      _negotiation_lapse: {
        Args: { p_negotiation_id: string; p_reason?: string }
        Returns: undefined
      }
      _negotiation_last_round: {
        Args: { p_negotiation_id: string }
        Returns: {
          amount: number
          id: string
          negotiation_id: string
          proposed_at: string
          proposed_by: Database["public"]["Enums"]["actor_type"]
          responded_at: string | null
          response: string | null
          round_number: number
        }
        SetofOptions: {
          from: "*"
          to: "price_negotiation_rounds"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      _negotiation_parse_endpoint: {
        Args: { p_value: Json }
        Returns: {
          point: unknown
          stage_id: string
        }[]
      }
      _negotiation_post_fare_correction: {
        Args: {
          p_agreed_amount: number
          p_negotiation: Database["public"]["Tables"]["price_negotiations"]["Row"]
          p_trip_id: string
        }
        Returns: undefined
      }
      _negotiation_pricing_source: { Args: never; Returns: string }
      _negotiation_roaming_params: {
        Args: {
          p_city_id: string
          p_driver_id: string
          p_rider_location: unknown
        }
        Returns: {
          eta_band: Database["public"]["Enums"]["eta_band"]
          expires_at: string
          open_distance_m: number
          pickup_radius_m: number
          round_cap: number
          round_timeout_s: number
        }[]
      }
      _negotiation_round_count: {
        Args: { p_negotiation_id: string }
        Returns: number
      }
      _parked_supply_bucket: { Args: { p_count: number }; Returns: string }
      _payment_token_payload: {
        Args: {
          p_amount_kobo: number
          p_driver_id: string
          p_exp: number
          p_trip_id: string
        }
        Returns: string
      }
      _pick_next_roaming_driver: {
        Args: { p_trip_id: string }
        Returns: {
          driver_id: string
          profile_id: string
          vehicle_id: string
        }[]
      }
      _planner_build_itinerary: {
        Args: {
          p_city_id: string
          p_destination_park_id: string
          p_origin_park_id: string
          p_route_path: string[]
          p_stage_path: string[]
        }
        Returns: Json
      }
      _planner_in_vehicle_s: {
        Args: {
          p_from_stage_id: string
          p_route_id: string
          p_to_stage_id: string
        }
        Returns: number
      }
      _planner_search_paths: {
        Args: {
          p_city_id: string
          p_destination_park_id: string
          p_k: number
          p_origin_park_id: string
        }
        Returns: {
          cost: number
          route_path: string[]
          stage_path: string[]
          transfer_count: number
        }[]
      }
      _planner_stage_point: { Args: { p_stage_id: string }; Returns: unknown }
      _planner_stages_at_park: {
        Args: { p_city_id: string; p_park_id: string }
        Returns: {
          mode_code: string
          route_id: string
          stage_id: string
        }[]
      }
      _planner_wait_s: {
        Args: {
          p_city_id: string
          p_from_stage_id: string
          p_route_id: string
          p_to_stage_id: string
        }
        Returns: number
      }
      _point_from_json: { Args: { p_loc: Json }; Returns: unknown }
      _postgis_deprecate: {
        Args: { newname: string; oldname: string; version: string }
        Returns: undefined
      }
      _postgis_index_extent: {
        Args: { col: string; tbl: unknown }
        Returns: unknown
      }
      _postgis_pgsql_version: { Args: never; Returns: string }
      _postgis_scripts_pgsql_version: { Args: never; Returns: string }
      _postgis_selectivity: {
        Args: { att_name: string; geom: unknown; mode?: string; tbl: unknown }
        Returns: number
      }
      _postgis_stats: {
        Args: { ""?: string; att_name: string; tbl: unknown }
        Returns: string
      }
      _prokind: { Args: { p_oid: unknown }; Returns: unknown }
      _query: { Args: { "": string }; Returns: string }
      _refine_vol: { Args: { "": string }; Returns: string }
      _resolve_roaming_presence: {
        Args: {
          p_city_id: string
          p_destination?: unknown
          p_driver_id: string
          p_session_id: string
          p_women_only?: boolean
        }
        Returns: {
          ambient_cell: string
          current_location: unknown
          driver_id: string
          mode_code: string
          profile_id: string
          vehicle_id: string
        }[]
      }
      _resolve_trip_driver:
        | {
            Args: {
              p_candidate: Json
              p_city_id: string
              p_leg: Json
              p_source: string
            }
            Returns: {
              driver_id: string
              profile_id: string
              vehicle_id: string
            }[]
          }
        | {
            Args: {
              p_candidate: Json
              p_city_id: string
              p_leg: Json
              p_source: string
              p_women_only?: boolean
            }
            Returns: {
              driver_id: string
              profile_id: string
              vehicle_id: string
            }[]
          }
      _rider_fare_confirm_source: { Args: never; Returns: string }
      _route_leg_ids_between: {
        Args: {
          p_from_stage_id: string
          p_route_id: string
          p_to_stage_id: string
        }
        Returns: string[]
      }
      _route_leg_segment_keys: {
        Args: {
          p_from_stage_id: string
          p_route_id: string
          p_to_stage_id: string
        }
        Returns: string[]
      }
      _slugify_graph_name: { Args: { p_name: string }; Returns: string }
      _snap_or_create_intelligence_park: {
        Args: {
          p_city_id: string
          p_label: string
          p_location: unknown
          p_source_id: string
        }
        Returns: string
      }
      _st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_crosses: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      _st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_intersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      _st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      _st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      _st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_sortablehash: { Args: { geom: unknown }; Returns: number }
      _st_touches: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_voronoi: {
        Args: {
          clip?: unknown
          g1: unknown
          return_polygons?: boolean
          tolerance?: number
        }
        Returns: unknown
      }
      _st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _table_privs: { Args: never; Returns: unknown[] }
      _temptypes: { Args: { "": string }; Returns: string }
      _todo: { Args: never; Returns: string }
      _trip_boarding_point: {
        Args: { p_trip: Database["public"]["Tables"]["trips"]["Row"] }
        Returns: unknown
      }
      _trip_chat_open: {
        Args: { v_trip: Database["public"]["Tables"]["trips"]["Row"] }
        Returns: boolean
      }
      _trip_lost_found_open: {
        Args: { v_trip: Database["public"]["Tables"]["trips"]["Row"] }
        Returns: boolean
      }
      _trip_pin_cleared: { Args: { p_trip_id: string }; Returns: boolean }
      _trip_planned_in_vehicle_s: {
        Args: { p_trip_id: string }
        Returns: number
      }
      _validate_config_value: {
        Args: { p_key: string; p_value: Json }
        Returns: undefined
      }
      _validate_load_flag: {
        Args: { p_city_id: string; p_load: Json; p_mode_code: string }
        Returns: undefined
      }
      abandon_stale_journeys: { Args: never; Returns: number }
      acknowledge_guarantor: { Args: { p_token: string }; Returns: Json }
      addauth: { Args: { "": string }; Returns: boolean }
      addgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              column_name: string
              new_dim: number
              new_srid_in: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
      admin_ack_sos: { Args: { p_id: string }; Returns: Json }
      admin_active_trips_map: { Args: { p_city_id: string }; Returns: Json }
      admin_approve_adjustment: {
        Args: { p_request_id: string }
        Returns: Json
      }
      admin_approve_verification: {
        Args: { p_verification_id: string; p_women_only_eligible?: boolean }
        Returns: Json
      }
      admin_can_access_city: { Args: { p_city: string }; Returns: boolean }
      admin_can_access_profile: {
        Args: { p_profile: string }
        Returns: boolean
      }
      admin_check_identity_duplicate: {
        Args: { p_verification_id: string }
        Returns: Json
      }
      admin_corporate_account_id: { Args: never; Returns: string }
      admin_corridor_analytics: {
        Args: {
          p_corridor_id: string
          p_cursor?: string
          p_from: string
          p_limit?: number
          p_to: string
        }
        Returns: Json
      }
      admin_create_api_key: {
        Args: {
          p_owner_organization: string
          p_rate_limit_per_min?: number
          p_scope: string[]
        }
        Returns: Json
      }
      admin_create_city: {
        Args: {
          p_centroid_lat: number
          p_centroid_lng: number
          p_config_overrides?: Json
          p_country_code: string
          p_dry_run?: boolean
          p_name: string
          p_slug: string
          p_state_region?: string
          p_status?: Database["public"]["Enums"]["city_status"]
        }
        Returns: Json
      }
      admin_create_corporate_account: {
        Args: {
          p_billing_email: string
          p_currency?: string
          p_deployment_id: string
          p_monthly_budget?: number
          p_name: string
        }
        Returns: Json
      }
      admin_create_operator_account: {
        Args: {
          p_deployment_id: string
          p_name: string
          p_subscription_tier?: string
          p_type: Database["public"]["Enums"]["operator_account_type"]
        }
        Returns: Json
      }
      admin_create_sponsored_placement: {
        Args: {
          p_active_from: string
          p_active_to: string
          p_advertiser: string
          p_content: Json
          p_context_type: Database["public"]["Enums"]["placement_context_type"]
          p_deployment_id: string
          p_target_reference: string
        }
        Returns: Json
      }
      admin_deactivate_graph_entity: {
        Args: { p_id: string; p_reason?: string; p_type: string }
        Returns: Json
      }
      admin_disable_admin: { Args: { p_user_id: string }; Returns: Json }
      admin_import_apply: {
        Args: { p_city_id: string; p_diff: Json }
        Returns: Json
      }
      admin_import_dry_run: {
        Args: { p_city_id: string; p_csv: string }
        Returns: Json
      }
      admin_invite_admin: {
        Args: {
          p_city_scope?: string[]
          p_deployment_id?: string
          p_display_name?: string
          p_email: string
          p_role: Database["public"]["Enums"]["admin_role"]
        }
        Returns: Json
      }
      admin_list_admins: {
        Args: { p_cursor?: string; p_limit?: number }
        Returns: Json
      }
      admin_log_view_document: {
        Args: { p_verification_id: string }
        Returns: Json
      }
      admin_manual_ledger_adjustment: {
        Args: { p_amount: number; p_driver_id: string; p_memo: string }
        Returns: Json
      }
      admin_notify_guarantor: { Args: { p_driver_id: string }; Returns: Json }
      admin_operator_account_id: { Args: never; Returns: string }
      admin_payout_positive_balance: {
        Args: { p_driver_id: string }
        Returns: Json
      }
      admin_presence_fanout: { Args: { p_city_id: string }; Returns: Json }
      admin_presence_snapshot: { Args: { p_city_id: string }; Returns: Json }
      admin_publish_field_entity: {
        Args: { p_reconciliation_id: string }
        Returns: Json
      }
      admin_publish_graph_entity: {
        Args: { p_payload: Json; p_type: string }
        Returns: Json
      }
      admin_reconcile_field_entity: {
        Args: {
          p_action: string
          p_reconciliation_id: string
          p_resolution?: Json
        }
        Returns: {
          created_at: string
          entity_key: string
          entity_type: string
          id: string
          published_target_id: string | null
          published_target_type: string | null
          resolution: Json | null
          resolved_at: string | null
          resolved_by: string | null
          status: string
          submission_a: string
          submission_b: string | null
          submission_c: string | null
          updated_at: string
          variance: Json | null
        }
        SetofOptions: {
          from: "*"
          to: "field_reconciliations"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_reject_verification: {
        Args: { p_reason: string; p_verification_id: string }
        Returns: Json
      }
      admin_resolve_sos: {
        Args: { p_id: string; p_note?: string; p_status: string }
        Returns: Json
      }
      admin_review_candidate_park: {
        Args: { action: string; id: string }
        Returns: Json
      }
      admin_review_fare_correction: {
        Args: { action: string; id: string; note?: string }
        Returns: Json
      }
      admin_review_flag: {
        Args: {
          p_action: string
          p_flag_id: string
          p_note?: string
          p_standing_transition_id?: number
        }
        Returns: Json
      }
      admin_review_geometry_correction: {
        Args: { action: string; id: string }
        Returns: Json
      }
      admin_review_route_inference: {
        Args: { action: string; id: string }
        Returns: Json
      }
      admin_revoke_api_key: { Args: { p_api_key_id: string }; Returns: Json }
      admin_rotate_driver_code: { Args: { p_driver_id: string }; Returns: Json }
      admin_set_config: {
        Args: {
          p_key: string
          p_reason?: string
          p_scope_id: string
          p_scope_type: Database["public"]["Enums"]["config_scope"]
          p_value: Json
        }
        Returns: Json
      }
      admin_set_country_schema: {
        Args: { p_code: string; p_verification_schema: Json }
        Returns: Json
      }
      admin_transition_standing: {
        Args: { p_driver_id: string; p_reason: string; p_to: string }
        Returns: Json
      }
      admin_triage_incident: {
        Args: {
          p_assigned_to?: string
          p_id: string
          p_severity?: number
          p_status: string
        }
        Returns: Json
      }
      admin_update_admin: {
        Args: {
          p_city_scope?: string[]
          p_clear_city_scope?: boolean
          p_deployment_id?: string
          p_role?: Database["public"]["Enums"]["admin_role"]
          p_user_id: string
        }
        Returns: Json
      }
      admin_update_graph_entity: {
        Args: { p_payload: Json; p_type: string }
        Returns: Json
      }
      admin_upsert_country: {
        Args: {
          p_active?: boolean
          p_code: string
          p_currency_code: string
          p_currency_minor_units?: number
          p_currency_symbol: string
          p_default_locale: string
          p_deployment_id: string
          p_name: string
          p_payment_provider?: string
          p_phone_prefix: string
          p_regulatory_flags?: Json
          p_timezone: string
        }
        Returns: Json
      }
      admin_upsert_settlement_agent: {
        Args: {
          p_active?: boolean
          p_agent_phone: string
          p_business_name: string
          p_city_id: string
          p_id: string
          p_lat?: number
          p_lng?: number
        }
        Returns: Json
      }
      along_geohash: {
        Args: { p: unknown; p_precision: number }
        Returns: string
      }
      ambient_count_bucket: { Args: { p_count: number }; Returns: string }
      ambient_demand: {
        Args: { p_lat: number; p_lng: number; p_radius_m: number }
        Returns: Json
      }
      ambient_vehicles: {
        Args: {
          p_dest_lat?: number
          p_dest_lng?: number
          p_lat: number
          p_lng: number
          p_radius_m: number
        }
        Returns: Json
      }
      angle_diff: { Args: { h1: number; h2: number }; Returns: number }
      api_fetch_od_cells: {
        Args: {
          p_api_key: string
          p_cursor?: string
          p_export_id: string
          p_limit?: number
        }
        Returns: Json
      }
      api_fetch_placement_stats: {
        Args: {
          p_api_key: string
          p_from?: string
          p_placement_id: string
          p_to?: string
        }
        Returns: Json
      }
      app_config_visible_to_user: {
        Args: {
          p_scope_id: string
          p_scope_type: Database["public"]["Enums"]["config_scope"]
        }
        Returns: boolean
      }
      apply_paystack_charge_success: {
        Args: { p_amount: number; p_metadata?: Json; p_reference: string }
        Returns: {
          amount: number
          balance_after: number
          created_at: string
          created_by_id: string | null
          created_by_type: Database["public"]["Enums"]["ledger_actor"]
          currency: string
          driver_id: string
          entry_type: Database["public"]["Enums"]["ledger_entry_type"]
          id: number
          idempotency_key: string
          memo: string | null
          settlement_id: string | null
          trip_extension_id: string | null
          trip_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "driver_ledger_entries"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      apply_paystack_transfer_success: {
        Args: { p_amount: number; p_metadata?: Json; p_reference: string }
        Returns: {
          amount: number
          balance_after: number
          created_at: string
          created_by_id: string | null
          created_by_type: Database["public"]["Enums"]["ledger_actor"]
          currency: string
          driver_id: string
          entry_type: Database["public"]["Enums"]["ledger_entry_type"]
          id: number
          idempotency_key: string
          memo: string | null
          settlement_id: string | null
          trip_extension_id: string | null
          trip_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "driver_ledger_entries"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      apply_threshold_policy: { Args: never; Returns: undefined }
      approach_band_from_walk_s: {
        Args: { p_city_id: string; p_walk_s: number }
        Returns: string
      }
      assert_payout_reauth: { Args: { p_user_id?: string }; Returns: undefined }
      audit_row_target_id: { Args: { p_row: Json }; Returns: string }
      auth_user_deployment_id: { Args: never; Returns: string }
      auto_boarding_check: { Args: { p_trip_id: string }; Returns: boolean }
      auto_in_transit_check: { Args: { p_trip_id: string }; Returns: boolean }
      bearing_deg: { Args: { a: unknown; b: unknown }; Returns: number }
      build_trip_view: {
        Args: { p_trip_id: string; p_viewer_id?: string }
        Returns: Json
      }
      cancel_trip: {
        Args: { p_reason?: string; p_trip_id: string }
        Returns: Json
      }
      candidate_token_hmac_key: { Args: never; Returns: string }
      cfg: {
        Args: { p_city?: string; p_corridor?: string; p_key: string }
        Returns: Json
      }
      cfg_num: {
        Args: { p_city?: string; p_corridor?: string; p_key: string }
        Returns: number
      }
      check_ledger_invariant: { Args: never; Returns: Json }
      check_qr_resolve_rate: {
        Args: { p_ip: string; p_limit?: number }
        Returns: boolean
      }
      city_centroid: { Args: { p_city_id: string }; Returns: Json }
      city_for_lat_lng: {
        Args: { p_lat: number; p_lng: number }
        Returns: string
      }
      city_for_point: { Args: { p: unknown }; Returns: string }
      city_graph_version: { Args: { p_city_id: string }; Returns: string }
      city_in_user_deployment: { Args: { p_city_id: string }; Returns: boolean }
      claim_bundle: {
        Args: {
          p_ack_rule_ids?: string[]
          p_layout_id: string
          p_rule_id: string
        }
        Returns: Json
      }
      claim_seat: {
        Args: {
          p_ack_rule_ids?: string[]
          p_expected_version: number
          p_layout_id: string
          p_seat_id: string
        }
        Returns: Json
      }
      cluster_candidate_parks: { Args: { p_city_id?: string }; Returns: Json }
      col_is_null:
        | {
            Args: {
              column_name: unknown
              description?: string
              schema_name: unknown
              table_name: unknown
            }
            Returns: string
          }
        | {
            Args: {
              column_name: unknown
              description?: string
              table_name: unknown
            }
            Returns: string
          }
      col_not_null:
        | {
            Args: {
              column_name: unknown
              description?: string
              schema_name: unknown
              table_name: unknown
            }
            Returns: string
          }
        | {
            Args: {
              column_name: unknown
              description?: string
              table_name: unknown
            }
            Returns: string
          }
      complete_rider_onboarding: {
        Args: { display_name?: string; home_city_id?: string }
        Returns: Json
      }
      complete_trip: {
        Args: { p_alighting?: Json; p_trip_id: string }
        Returns: Json
      }
      compute_approach_band: { Args: { p_trip_id: string }; Returns: string }
      compute_field_variance: {
        Args: { p_submission_a: string; p_submission_b: string }
        Returns: Json
      }
      compute_identity_hash: {
        Args: { p_document_type: string; p_normalized_id: string }
        Returns: string
      }
      compute_risk_scores: { Args: never; Returns: undefined }
      compute_trust_weights: { Args: never; Returns: undefined }
      conductor_board: { Args: { p_code: string }; Returns: Json }
      conductor_set_seat: {
        Args: { p_code: string; p_seat_id: string; p_status: string }
        Returns: Json
      }
      config_default: {
        Args: {
          p_key: string
          p_scope_id?: string
          p_scope_type?: Database["public"]["Enums"]["config_scope"]
          p_value: Json
        }
        Returns: undefined
      }
      confirm_agent_settlement: {
        Args: { p_agent_code: string; p_amount: number }
        Returns: Json
      }
      confirm_fare: {
        Args: { p_outcome: string; p_paid_amount?: number; p_trip_id: string }
        Returns: Json
      }
      confirm_graph_value: {
        Args: {
          p_confirmer_profile_id?: string
          p_confirmer_role?: string
          p_target_id: string
          p_target_type: string
          p_trip_id?: string
          p_value: Json
        }
        Returns: string
      }
      confirm_na_me_match: {
        Args: { p_proof: Json; p_trip_id: string }
        Returns: Json
      }
      confirmer_trust_weight: {
        Args: { p_city_id?: string; p_profile_id: string; p_role: string }
        Returns: number
      }
      corporate_allocate_trip: { Args: { p_trip_id: string }; Returns: string }
      corporate_invite_member: {
        Args: {
          p_default_policy_id?: string
          p_department?: string
          p_employee_ref?: string
          p_phone_e164: string
        }
        Returns: Json
      }
      corporate_overview: { Args: never; Returns: Json }
      corporate_update_member: {
        Args: {
          p_active?: boolean
          p_default_policy_id?: string
          p_department?: string
          p_employee_ref?: string
          p_rider_id: string
        }
        Returns: Json
      }
      corporate_upsert_policy: {
        Args: {
          p_active?: boolean
          p_allowed_hours?: Json
          p_id?: string
          p_max_per_trip?: number
          p_name: string
          p_subsidy_pct: number
        }
        Returns: Json
      }
      country_currency_meta: { Args: { p_country_code: string }; Returns: Json }
      create_agent_code: { Args: { p_amount: number }; Returns: Json }
      create_itinerary: {
        Args: { p_load?: Json; p_stops: Json }
        Returns: Json
      }
      create_payment_request: { Args: { p_trip_id: string }; Returns: Json }
      create_trip_share: {
        Args: {
          p_contact_name?: string
          p_contact_phone?: string
          p_journey_id: string
        }
        Returns: Json
      }
      current_profile_id: { Args: never; Returns: string }
      deactivate_route_profile: { Args: { p_id: string }; Returns: undefined }
      decay_confidence: { Args: never; Returns: undefined }
      delete_emergency_contact: { Args: { p_id: string }; Returns: Json }
      delete_ride_rule: { Args: { p_rule_id: string }; Returns: Json }
      diag:
        | {
            Args: { msg: unknown }
            Returns: {
              error: true
            } & "Could not choose the best candidate function between: public.diag(msg => text), public.diag(msg => anyelement). Try renaming the parameters or the function itself in the database so function overloading can be resolved"
          }
        | {
            Args: { msg: string }
            Returns: {
              error: true
            } & "Could not choose the best candidate function between: public.diag(msg => text), public.diag(msg => anyelement). Try renaming the parameters or the function itself in the database so function overloading can be resolved"
          }
      diag_test_name: { Args: { "": string }; Returns: string }
      disablelongtransactions: { Args: never; Returns: string }
      dispatch_cascade_step: {
        Args: {
          p_declining_driver_id?: string
          p_reason?: string
          p_trip_id: string
        }
        Returns: Json
      }
      distance_m: { Args: { a: unknown; b: unknown }; Returns: number }
      do_tap:
        | { Args: never; Returns: string[] }
        | { Args: { "": string }; Returns: string[] }
      driver_balance: { Args: never; Returns: Json }
      driver_earnings_context: { Args: { p_days?: number }; Returns: Json }
      driver_is_matchable: { Args: { p_driver_id: string }; Returns: boolean }
      driver_ledger: {
        Args: { p_cursor?: string; p_limit?: number }
        Returns: Json
      }
      driver_manifest: { Args: never; Returns: Json }
      dropgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { column_name: string; table_name: string }; Returns: string }
      dropgeometrytable:
        | {
            Args: {
              catalog_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { schema_name: string; table_name: string }; Returns: string }
        | { Args: { table_name: string }; Returns: string }
      enablelongtransactions: { Args: never; Returns: string }
      ensure_partitions: { Args: never; Returns: undefined }
      equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      expire_payments: { Args: never; Returns: number }
      expire_requests: { Args: never; Returns: number }
      fail:
        | { Args: never; Returns: string }
        | { Args: { "": string }; Returns: string }
      fare_history: { Args: { p_corridor: string }; Returns: Json }
      fare_outlier_guard: {
        Args: {
          p_city_id?: string
          p_from_stage_id: string
          p_proposed_fare: number
          p_route_id: string
        }
        Returns: {
          is_outlier: boolean
          mad: number
          neighbour_median: number
        }[]
      }
      fare_shield: {
        Args: { p_corridor: string; p_hour: number }
        Returns: Json
      }
      findfuncs: { Args: { "": string }; Returns: string[] }
      fingerprint_collusion_factor: {
        Args: { p_city_id?: string; p_profile_id: string }
        Returns: number
      }
      finish: { Args: { exception_on_failure?: boolean }; Returns: string[] }
      generate_corporate_invoices: {
        Args: { p_period_end: string; p_period_start: string }
        Returns: Json
      }
      generate_corporate_invoices_monthly: { Args: never; Returns: Json }
      generate_driver_code: { Args: never; Returns: string }
      generate_na_me_pairing: {
        Args: { p_city_id: string; p_driver_id: string; p_rider_id: string }
        Returns: {
          color_token: string
          label: string
          shape: string
        }[]
      }
      geohash_centroid: {
        Args: { p_geohash: string; p_precision: number }
        Returns: unknown
      }
      geometry: { Args: { "": string }; Returns: unknown }
      geometry_above: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_below: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_cmp: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_contained_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_distance_box: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_distance_centroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_eq: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_ge: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_gt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_le: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_left: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_lt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overabove: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overbelow: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overleft: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overright: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_right: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_within: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geomfromewkt: { Args: { "": string }; Returns: unknown }
      get_wallet: { Args: never; Returns: Json }
      gettransactionid: { Args: never; Returns: unknown }
      graph_bundle_compact: {
        Args: {
          p_city_id: string
          p_max_legs: number
          p_max_parks: number
          p_max_stages: number
        }
        Returns: Json
      }
      graph_target_city_id: {
        Args: { p_target_id: string; p_target_type: string }
        Returns: string
      }
      hail_roaming: {
        Args: {
          p_candidate_token: string
          p_client_ref: string
          p_destination: Json
          p_load?: Json
          p_women_only: boolean
        }
        Returns: Json
      }
      has_admin_role: { Args: { roles: string[] }; Returns: boolean }
      has_unique: { Args: { "": string }; Returns: string }
      heading_sector_counts: { Args: { p_sectors: number[] }; Returns: Json }
      hold_seat: {
        Args: {
          p_ack_rule_ids?: string[]
          p_expected_version: number
          p_layout_id: string
          p_seat_id: string
          p_walk_minutes?: number
        }
        Returns: Json
      }
      identity_hash_pepper: { Args: never; Returns: string }
      in_todo: { Args: never; Returns: boolean }
      infer_confirmer_role: { Args: { p_profile_id: string }; Returns: string }
      insert_planner_query: {
        Args: {
          p_candidate_count: number
          p_candidates: Json
          p_city_id: string
          p_degraded: boolean
          p_dest_lat: number
          p_dest_lng: number
          p_direct_count: number
          p_filters: Json
          p_id: string
          p_latency_ms: number
          p_origin_lat: number
          p_origin_lng: number
          p_rider_id: string
        }
        Returns: string
      }
      is_admin: { Args: never; Returns: boolean }
      is_empty: { Args: { "": string }; Returns: string }
      isnt_empty: { Args: { "": string }; Returns: string }
      itinerary_match_next: { Args: { p_itinerary_id: string }; Returns: Json }
      itinerary_prepare_context: { Args: { p_trip_id: string }; Returns: Json }
      itinerary_state: { Args: { p_itinerary_id: string }; Returns: Json }
      ledger_post: {
        Args: {
          p_actor_id?: string
          p_actor_type?: Database["public"]["Enums"]["ledger_actor"]
          p_amount: number
          p_currency: string
          p_driver_id: string
          p_entry_type: Database["public"]["Enums"]["ledger_entry_type"]
          p_idempotency_key?: string
          p_memo?: string
          p_refs?: Json
        }
        Returns: {
          amount: number
          balance_after: number
          created_at: string
          created_by_id: string | null
          created_by_type: Database["public"]["Enums"]["ledger_actor"]
          currency: string
          driver_id: string
          entry_type: Database["public"]["Enums"]["ledger_entry_type"]
          id: number
          idempotency_key: string
          memo: string | null
          settlement_id: string | null
          trip_extension_id: string | null
          trip_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "driver_ledger_entries"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      list_emergency_contacts: { Args: never; Returns: Json }
      list_favourites: { Args: never; Returns: Json }
      list_pickup_events: { Args: never; Returns: Json }
      list_trip_messages: { Args: { p_trip_id: string }; Returns: Json }
      lives_ok: { Args: { "": string }; Returns: string }
      longtransactionsenabled: { Args: never; Returns: boolean }
      mark_boarded: { Args: { p_trip_id: string }; Returns: Json }
      mark_no_show: { Args: { p_trip_id: string }; Returns: Json }
      mark_trip_messages_read: { Args: { p_trip_id: string }; Returns: number }
      my_day_setup: { Args: never; Returns: Json }
      my_rest_status: { Args: never; Returns: Json }
      my_route_profiles: { Args: never; Returns: Json }
      my_standing_history: { Args: never; Returns: Json }
      my_verifications: { Args: never; Returns: Json }
      na_me_tap_options: { Args: { p_trip_id: string }; Returns: Json }
      nearby_fuel: {
        Args: { p_lat: number; p_lng: number; p_radius_m: number }
        Returns: Json
      }
      nearby_settlement_agents: { Args: { p_location?: Json }; Returns: Json }
      negotiation_clock_tick: { Args: never; Returns: Json }
      negotiation_round: {
        Args: { p_action: string; p_amount?: number; p_negotiation_id: string }
        Returns: Json
      }
      negotiation_split: { Args: { p_negotiation_id: string }; Returns: Json }
      no_plan: { Args: never; Returns: boolean[] }
      normalize_identity_id: {
        Args: { p_document_type: string; p_raw: string }
        Returns: string
      }
      num_failed: { Args: never; Returns: number }
      online_vehicle_cards: {
        Args: { p_city_id: string; p_preset_ids?: string[]; p_query?: string }
        Returns: Json
      }
      open_conductor_session: { Args: never; Returns: Json }
      open_negotiation: {
        Args: {
          p_candidate_token?: string
          p_client_ref: string
          p_context: Database["public"]["Enums"]["negotiation_context"]
          p_driver_id?: string
          p_from: Json
          p_to: Json
        }
        Returns: Json
      }
      open_pickup_event: {
        Args: {
          p_client_ref: string
          p_ends: string
          p_lat: number
          p_lng: number
          p_name: string
          p_starts: string
        }
        Returns: Json
      }
      operator_driver_aggregates: {
        Args: { p_from: string; p_to: string }
        Returns: Json
      }
      operator_overview: {
        Args: { p_from: string; p_to: string }
        Returns: Json
      }
      os_name: { Args: never; Returns: string }
      pass:
        | { Args: never; Returns: string }
        | { Args: { "": string }; Returns: string }
      payment_receipt_payload: {
        Args: { p_payment_id: string; p_receipt_token?: string }
        Returns: Json
      }
      payment_token_hmac_key: { Args: never; Returns: string }
      peek_log_otp: { Args: { p_phone: string }; Returns: string }
      persist_driver_payout_bank: {
        Args: {
          p_bank_last4: string
          p_bank_name?: string
          p_subaccount_code: string
        }
        Returns: Json
      }
      pg_version: { Args: never; Returns: string }
      pg_version_num: { Args: never; Returns: number }
      pgtap_version: { Args: never; Returns: number }
      places_search_graph: {
        Args: {
          p_city_id: string
          p_limit: number
          p_min_similarity: number
          p_near_lat: number
          p_near_lng: number
          p_q: string
          p_radius_m: number
        }
        Returns: {
          area: string
          distance_m: number
          id: string
          kind: string
          lat: number
          lng: number
          name: string
          rank_score: number
        }[]
      }
      planner_decompose: {
        Args: {
          p_city_id?: string
          p_destination_park_id: string
          p_origin_park_id: string
        }
        Returns: Json[]
      }
      planner_decompose_latlng: {
        Args: {
          p_city_id: string
          p_dest_lat: number
          p_dest_lng: number
          p_filters?: Json
          p_origin_lat: number
          p_origin_lng: number
        }
        Returns: Json[]
      }
      planner_direct_candidates: {
        Args: {
          p_city_id: string
          p_destination: unknown
          p_filters?: Json
          p_origin: unknown
        }
        Returns: Json[]
      }
      planner_direct_candidates_latlng: {
        Args: {
          p_city_id: string
          p_dest_lat: number
          p_dest_lng: number
          p_filters?: Json
          p_origin_lat: number
          p_origin_lng: number
        }
        Returns: Json[]
      }
      populate_geometry_columns:
        | { Args: { tbl_oid: unknown; use_typmod?: boolean }; Returns: number }
        | { Args: { use_typmod?: boolean }; Returns: string }
      post_trip_message: {
        Args: {
          p_body: string
          p_client_ref: string
          p_thread?: string
          p_trip_id: string
        }
        Returns: Json
      }
      postgis_constraint_dims: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_srid: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_type: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: string
      }
      postgis_extensions_upgrade: { Args: never; Returns: string }
      postgis_full_version: { Args: never; Returns: string }
      postgis_geos_version: { Args: never; Returns: string }
      postgis_lib_build_date: { Args: never; Returns: string }
      postgis_lib_revision: { Args: never; Returns: string }
      postgis_lib_version: { Args: never; Returns: string }
      postgis_libjson_version: { Args: never; Returns: string }
      postgis_liblwgeom_version: { Args: never; Returns: string }
      postgis_libprotobuf_version: { Args: never; Returns: string }
      postgis_libxml_version: { Args: never; Returns: string }
      postgis_proj_version: { Args: never; Returns: string }
      postgis_scripts_build_date: { Args: never; Returns: string }
      postgis_scripts_installed: { Args: never; Returns: string }
      postgis_scripts_released: { Args: never; Returns: string }
      postgis_svn_version: { Args: never; Returns: string }
      postgis_type_name: {
        Args: {
          coord_dimension: number
          geomname: string
          use_new_name?: boolean
        }
        Returns: string
      }
      postgis_version: { Args: never; Returns: string }
      postgis_wagyu_version: { Args: never; Returns: string }
      presence_fanout_targets: {
        Args: never
        Returns: {
          centroid_lat: number
          centroid_lng: number
          city_id: string
          city_slug: string
          geohash5: string
          radius_m: number
        }[]
      }
      presence_is_fresh: {
        Args: { p_city_id: string; p_last_ping_at: string }
        Returns: boolean
      }
      presence_ping: {
        Args: {
          p_accuracy_m: number
          p_heading: number
          p_location: Json
          p_seats_available?: number
          p_speed_mps: number
        }
        Returns: Json
      }
      presence_plausible: {
        Args: {
          p_city_id: string
          p_declared_route_leg_id: string
          p_declared_route_profile_id: string
          p_destination: unknown
          p_heading: number
          p_location: unknown
          p_nearest_stage_id: string
          p_speed_mps: number
        }
        Returns: boolean
      }
      presence_retention: { Args: never; Returns: undefined }
      presence_stale: { Args: never; Returns: undefined }
      promote_candidates: { Args: never; Returns: undefined }
      propose_extension: {
        Args: { p_new_alight: Json; p_trip_id: string }
        Returns: Json
      }
      qr_suggested_amounts: { Args: { p_driver_id: string }; Returns: Json }
      raise_sos: {
        Args: {
          p_accuracy_m?: number
          p_journey_id?: string
          p_location?: Json
          p_trip_id?: string
        }
        Returns: Json
      }
      rate_trip: {
        Args: {
          p_comment?: string
          p_score: number
          p_tags?: string[]
          p_trip_id: string
        }
        Returns: Json
      }
      realtime_admin_city: {
        Args: { p_topic: string; p_user_id: string }
        Returns: boolean
      }
      realtime_ambient_topic: { Args: { p_topic: string }; Returns: boolean }
      realtime_driver_self: {
        Args: { p_topic: string; p_user_id: string }
        Returns: boolean
      }
      realtime_negotiation_party: {
        Args: { p_topic: string; p_user_id: string }
        Returns: boolean
      }
      realtime_trip_chat_party: {
        Args: { p_topic: string; p_uid: string }
        Returns: boolean
      }
      realtime_trip_party: {
        Args: { p_topic: string; p_user_id: string }
        Returns: boolean
      }
      reconcile_cancelled_trips: { Args: never; Returns: undefined }
      reconcile_corporate_invoice: {
        Args: { p_invoice_id: string }
        Returns: Json
      }
      reconcile_field_submission: {
        Args: { p_submission_id: string }
        Returns: string
      }
      reconcile_split_settlements: {
        Args: { p_day: string; p_provider_totals?: Json }
        Returns: number
      }
      record_coverage_gap: {
        Args: {
          p_city_id: string
          p_destination: unknown
          p_origin: unknown
          p_rider_id: string
        }
        Returns: Json
      }
      record_coverage_gap_latlng: {
        Args: {
          p_city_id: string
          p_dest_lat: number
          p_dest_lng: number
          p_origin_lat: number
          p_origin_lng: number
          p_rider_id: string
        }
        Returns: Json
      }
      record_driver_rest: {
        Args: {
          p_ended_at: string
          p_idempotency_key: string
          p_started_at: string
        }
        Returns: Json
      }
      record_fare_observation: {
        Args: {
          p_amount_minor: number
          p_client_ref: string
          p_corridor: string
          p_hour: number
          p_kind: string
        }
        Returns: Json
      }
      record_fuel_note: {
        Args: {
          p_client_ref: string
          p_label: string
          p_lat: number
          p_lng: number
          p_price_naira: number
        }
        Returns: Json
      }
      record_guardian_event: {
        Args: {
          p_escalate?: boolean
          p_idempotency_key: string
          p_kind: string
          p_location?: Json
          p_trip_id: string
        }
        Returns: Json
      }
      record_log_otp: {
        Args: { p_otp: string; p_phone: string }
        Returns: undefined
      }
      record_phone_reauth: { Args: never; Returns: string }
      record_placement_counter: {
        Args: { p_metric: string; p_placement_id: string }
        Returns: undefined
      }
      refresh_trip_eta: { Args: { p_trip_id: string }; Returns: Json }
      refresh_wait: { Args: { p_trip_id: string }; Returns: Json }
      regenerate_trip_pin: { Args: { p_trip_id: string }; Returns: Json }
      register_device_token: {
        Args: { p_app: string; p_platform: string; p_token: string }
        Returns: undefined
      }
      register_guarantor: {
        Args: {
          p_guarantor_type: Database["public"]["Enums"]["guarantor_type"]
          p_name: string
          p_phone_e164: string
          p_profile_id?: string
        }
        Returns: string
      }
      register_vehicle: {
        Args: {
          p_color?: string
          p_make_model?: string
          p_mode_code: string
          p_owner_is_me: boolean
          p_owner_name?: string
          p_owner_phone?: string
          p_plate_number: string
          p_seat_capacity: number
        }
        Returns: Json
      }
      release_match: { Args: { p_trip_id: string }; Returns: Json }
      release_seat: {
        Args: { p_layout_id: string; p_seat_id: string }
        Returns: Json
      }
      remove_rider_payment_method: {
        Args: { p_payment_method_id: string }
        Returns: undefined
      }
      report_incident: {
        Args: {
          p_attachment_paths?: string[]
          p_description?: string
          p_trip_id?: string
          p_type?: string
        }
        Returns: Json
      }
      request_qr_sticker: { Args: never; Returns: Json }
      request_route: {
        Args: { p_client_ref: string; p_corridor: string }
        Returns: Json
      }
      request_trip: {
        Args: {
          p_candidate_id: string
          p_client_ref: string
          p_leg_index: number
          p_load?: Json
          p_women_only: boolean
        }
        Returns: Json
      }
      resolve_fare: {
        Args: {
          p_city_id?: string
          p_driver_id?: string
          p_from_point?: unknown
          p_from_stage_id?: string
          p_load?: Json
          p_mode_code?: string
          p_profile_id?: string
          p_rider_id?: string
          p_route_id?: string
          p_to_point?: unknown
          p_to_stage_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["fare_resolution"]
        SetofOptions: {
          from: "*"
          to: "fare_resolution"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      resolve_qr_driver: {
        Args: { p_driver_code: string; p_rider_id?: string; p_token?: string }
        Returns: Json
      }
      resolve_sponsored_placements: {
        Args: {
          p_context_type: Database["public"]["Enums"]["placement_context_type"]
          p_deployment_id?: string
          p_target_reference: string
        }
        Returns: Json
      }
      respond_extension: {
        Args: { p_extension_id: string; p_response: string }
        Returns: Json
      }
      respond_to_trip: {
        Args: { p_action: string; p_decline_reason?: string; p_trip_id: string }
        Returns: Json
      }
      revoke_trip_share: { Args: { p_share_id: string }; Returns: Json }
      rider_no_show_review: { Args: never; Returns: undefined }
      rider_trip_broadcast_payload: {
        Args: { p_event_type: string; p_message?: string; p_trip_id: string }
        Returns: Json
      }
      rider_trust_weight: {
        Args: { p_city_id?: string; p_rider_id: string }
        Returns: number
      }
      rotate_driver_code: { Args: never; Returns: Json }
      round_to_minor: {
        Args: { p_amount: number; p_city_id: string }
        Returns: number
      }
      route_leg_segment_keys: {
        Args: {
          p_from_stage_id: string
          p_route_id: string
          p_to_stage_id: string
        }
        Returns: string[]
      }
      runtests:
        | { Args: never; Returns: string[] }
        | { Args: { "": string }; Returns: string[] }
      save_earnings_goal: {
        Args: { p_target_minor: number }
        Returns: undefined
      }
      save_favourite: {
        Args: { p_driver_id: string; p_on: boolean }
        Returns: undefined
      }
      save_guardian_prefs: {
        Args: {
          p_check_in_minutes?: number
          p_enabled: boolean
          p_idempotency_key?: string
          p_long_stop_minutes?: number
          p_off_route_m?: number
          p_safe_word?: string
        }
        Returns: Json
      }
      save_rest_prefs: {
        Args: {
          p_drive_minutes?: number
          p_idempotency_key?: string
          p_rest_minutes?: number
        }
        Returns: Json
      }
      save_ride_rule: {
        Args: {
          p_body?: string
          p_enabled?: boolean
          p_params?: Json
          p_preset_id?: string
          p_rule_id?: string
          p_target_ref?: string
          p_title?: string
          p_vehicle_id: string
        }
        Returns: Json
      }
      save_vehicle_layout: {
        Args: {
          p_activate?: boolean
          p_layout: Json
          p_name: string
          p_vehicle_id: string
        }
        Returns: Json
      }
      seat_board: { Args: { p_layout_id?: string }; Returns: Json }
      sector8: { Args: { p_bearing: number }; Returns: number }
      segment_speed_profiles_lookup: {
        Args: {
          p_city_id: string
          p_dow_bucket: number
          p_hour_bucket: number
          p_segment_keys: string[]
        }
        Returns: {
          median_speed_mps: number
          sample_count: number
          segment_key: string
        }[]
      }
      set_accepts_digital: { Args: { p_enabled: boolean }; Returns: Json }
      set_all_seats: {
        Args: { p_layout_id: string; p_status: string }
        Returns: Json
      }
      set_default_rider_payment_method: {
        Args: { p_payment_method_id: string }
        Returns: undefined
      }
      set_driver_city: { Args: { p_city_id: string }; Returns: undefined }
      set_home_city: { Args: { p_city_id: string }; Returns: undefined }
      set_presence: {
        Args: {
          p_declared_route_leg_id?: string
          p_declared_route_profile_id?: string
          p_heading?: number
          p_location: Json
          p_park_id?: string
          p_seats_available: number
          p_status: string
        }
        Returns: Json
      }
      set_seat_status: {
        Args: { p_layout_id: string; p_seat_id: string; p_status: string }
        Returns: Json
      }
      shared_trip_view: { Args: { p_token: string }; Returns: Json }
      show_limit: { Args: never; Returns: number }
      show_trgm: { Args: { "": string }; Returns: string[] }
      sign_candidate_token: {
        Args: { p_city_id: string; p_driver_id: string; p_session_id: string }
        Returns: string
      }
      sign_payment_token: {
        Args: {
          p_amount: number
          p_city_id: string
          p_driver_id: string
          p_trip_id: string
        }
        Returns: string
      }
      skip:
        | { Args: { "": string }; Returns: string }
        | { Args: { how_many: number; why: string }; Returns: string }
      snap_stage: {
        Args: { p: unknown; p_city_id?: string; p_radius_m?: number }
        Returns: string
      }
      st_3dclosestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3ddistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_3dlongestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmakebox: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmaxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dshortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_addpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_angle:
        | { Args: { line1: unknown; line2: unknown }; Returns: number }
        | {
            Args: { pt1: unknown; pt2: unknown; pt3: unknown; pt4?: unknown }
            Returns: number
          }
      st_area:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_asencodedpolyline: {
        Args: { geom: unknown; nprecision?: number }
        Returns: string
      }
      st_asewkt: { Args: { "": string }; Returns: string }
      st_asgeojson:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: {
              geom_column?: string
              maxdecimaldigits?: number
              pretty_bool?: boolean
              r: Record<string, unknown>
            }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_asgml:
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
            }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
      st_askml:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_aslatlontext: {
        Args: { geom: unknown; tmpl?: string }
        Returns: string
      }
      st_asmarc21: { Args: { format?: string; geom: unknown }; Returns: string }
      st_asmvtgeom: {
        Args: {
          bounds: unknown
          buffer?: number
          clip_geom?: boolean
          extent?: number
          geom: unknown
        }
        Returns: unknown
      }
      st_assvg:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_astext: { Args: { "": string }; Returns: string }
      st_astwkb:
        | {
            Args: {
              geom: unknown
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown[]
              ids: number[]
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
      st_asx3d: {
        Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
        Returns: string
      }
      st_azimuth:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: number }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
      st_boundingdiagonal: {
        Args: { fits?: boolean; geom: unknown }
        Returns: unknown
      }
      st_buffer:
        | {
            Args: { geom: unknown; options?: string; radius: number }
            Returns: unknown
          }
        | {
            Args: { geom: unknown; quadsegs: number; radius: number }
            Returns: unknown
          }
      st_centroid: { Args: { "": string }; Returns: unknown }
      st_clipbybox2d: {
        Args: { box: unknown; geom: unknown }
        Returns: unknown
      }
      st_closestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_collect: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_concavehull: {
        Args: {
          param_allow_holes?: boolean
          param_geom: unknown
          param_pctconvex: number
        }
        Returns: unknown
      }
      st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_coorddim: { Args: { geometry: unknown }; Returns: number }
      st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_crosses: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_curvetoline: {
        Args: { flags?: number; geom: unknown; tol?: number; toltype?: number }
        Returns: unknown
      }
      st_delaunaytriangles: {
        Args: { flags?: number; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_difference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_disjoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_distance:
        | {
            Args: { geog1: unknown; geog2: unknown; use_spheroid?: boolean }
            Returns: number
          }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
      st_distancesphere:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | {
            Args: { geom1: unknown; geom2: unknown; radius: number }
            Returns: number
          }
      st_distancespheroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_expand:
        | { Args: { box: unknown; dx: number; dy: number }; Returns: unknown }
        | {
            Args: { box: unknown; dx: number; dy: number; dz?: number }
            Returns: unknown
          }
        | {
            Args: {
              dm?: number
              dx: number
              dy: number
              dz?: number
              geom: unknown
            }
            Returns: unknown
          }
      st_force3d: { Args: { geom: unknown; zvalue?: number }; Returns: unknown }
      st_force3dm: {
        Args: { geom: unknown; mvalue?: number }
        Returns: unknown
      }
      st_force3dz: {
        Args: { geom: unknown; zvalue?: number }
        Returns: unknown
      }
      st_force4d: {
        Args: { geom: unknown; mvalue?: number; zvalue?: number }
        Returns: unknown
      }
      st_generatepoints:
        | { Args: { area: unknown; npoints: number }; Returns: unknown }
        | {
            Args: { area: unknown; npoints: number; seed: number }
            Returns: unknown
          }
      st_geogfromtext: { Args: { "": string }; Returns: unknown }
      st_geographyfromtext: { Args: { "": string }; Returns: unknown }
      st_geohash:
        | { Args: { geog: unknown; maxchars?: number }; Returns: string }
        | { Args: { geom: unknown; maxchars?: number }; Returns: string }
      st_geomcollfromtext: { Args: { "": string }; Returns: unknown }
      st_geometricmedian: {
        Args: {
          fail_if_not_converged?: boolean
          g: unknown
          max_iter?: number
          tolerance?: number
        }
        Returns: unknown
      }
      st_geometryfromtext: { Args: { "": string }; Returns: unknown }
      st_geomfromewkt: { Args: { "": string }; Returns: unknown }
      st_geomfromgeojson:
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": string }; Returns: unknown }
      st_geomfromgml: { Args: { "": string }; Returns: unknown }
      st_geomfromkml: { Args: { "": string }; Returns: unknown }
      st_geomfrommarc21: { Args: { marc21xml: string }; Returns: unknown }
      st_geomfromtext: { Args: { "": string }; Returns: unknown }
      st_gmltosql: { Args: { "": string }; Returns: unknown }
      st_hasarc: { Args: { geometry: unknown }; Returns: boolean }
      st_hausdorffdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_hexagon: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_hexagongrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_interpolatepoint: {
        Args: { line: unknown; point: unknown }
        Returns: number
      }
      st_intersection: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_intersects:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_isvaliddetail: {
        Args: { flags?: number; geom: unknown }
        Returns: Database["public"]["CompositeTypes"]["valid_detail"]
        SetofOptions: {
          from: "*"
          to: "valid_detail"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      st_length:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_letters: { Args: { font?: Json; letters: string }; Returns: unknown }
      st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      st_linefromencodedpolyline: {
        Args: { nprecision?: number; txtin: string }
        Returns: unknown
      }
      st_linefromtext: { Args: { "": string }; Returns: unknown }
      st_linelocatepoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_linetocurve: { Args: { geometry: unknown }; Returns: unknown }
      st_locatealong: {
        Args: { geometry: unknown; leftrightoffset?: number; measure: number }
        Returns: unknown
      }
      st_locatebetween: {
        Args: {
          frommeasure: number
          geometry: unknown
          leftrightoffset?: number
          tomeasure: number
        }
        Returns: unknown
      }
      st_locatebetweenelevations: {
        Args: { fromelevation: number; geometry: unknown; toelevation: number }
        Returns: unknown
      }
      st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makebox2d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makeline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makevalid: {
        Args: { geom: unknown; params: string }
        Returns: unknown
      }
      st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_minimumboundingcircle: {
        Args: { inputgeom: unknown; segs_per_quarter?: number }
        Returns: unknown
      }
      st_mlinefromtext: { Args: { "": string }; Returns: unknown }
      st_mpointfromtext: { Args: { "": string }; Returns: unknown }
      st_mpolyfromtext: { Args: { "": string }; Returns: unknown }
      st_multilinestringfromtext: { Args: { "": string }; Returns: unknown }
      st_multipointfromtext: { Args: { "": string }; Returns: unknown }
      st_multipolygonfromtext: { Args: { "": string }; Returns: unknown }
      st_node: { Args: { g: unknown }; Returns: unknown }
      st_normalize: { Args: { geom: unknown }; Returns: unknown }
      st_offsetcurve: {
        Args: { distance: number; line: unknown; params?: string }
        Returns: unknown
      }
      st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_perimeter: {
        Args: { geog: unknown; use_spheroid?: boolean }
        Returns: number
      }
      st_pointfromtext: { Args: { "": string }; Returns: unknown }
      st_pointm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
        }
        Returns: unknown
      }
      st_pointz: {
        Args: {
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_pointzm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_polyfromtext: { Args: { "": string }; Returns: unknown }
      st_polygonfromtext: { Args: { "": string }; Returns: unknown }
      st_project: {
        Args: { azimuth: number; distance: number; geog: unknown }
        Returns: unknown
      }
      st_quantizecoordinates: {
        Args: {
          g: unknown
          prec_m?: number
          prec_x: number
          prec_y?: number
          prec_z?: number
        }
        Returns: unknown
      }
      st_reduceprecision: {
        Args: { geom: unknown; gridsize: number }
        Returns: unknown
      }
      st_relate: { Args: { geom1: unknown; geom2: unknown }; Returns: string }
      st_removerepeatedpoints: {
        Args: { geom: unknown; tolerance?: number }
        Returns: unknown
      }
      st_segmentize: {
        Args: { geog: unknown; max_segment_length: number }
        Returns: unknown
      }
      st_setsrid:
        | { Args: { geog: unknown; srid: number }; Returns: unknown }
        | { Args: { geom: unknown; srid: number }; Returns: unknown }
      st_sharedpaths: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_shortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_simplifypolygonhull: {
        Args: { geom: unknown; is_outer?: boolean; vertex_fraction: number }
        Returns: unknown
      }
      st_split: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_square: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_squaregrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_srid:
        | { Args: { geog: unknown }; Returns: number }
        | { Args: { geom: unknown }; Returns: number }
      st_subdivide: {
        Args: { geom: unknown; gridsize?: number; maxvertices?: number }
        Returns: unknown[]
      }
      st_swapordinates: {
        Args: { geom: unknown; ords: unknown }
        Returns: unknown
      }
      st_symdifference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_symmetricdifference: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_tileenvelope: {
        Args: {
          bounds?: unknown
          margin?: number
          x: number
          y: number
          zoom: number
        }
        Returns: unknown
      }
      st_touches: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_transform:
        | {
            Args: { from_proj: string; geom: unknown; to_proj: string }
            Returns: unknown
          }
        | {
            Args: { from_proj: string; geom: unknown; to_srid: number }
            Returns: unknown
          }
        | { Args: { geom: unknown; to_proj: string }; Returns: unknown }
      st_triangulatepolygon: { Args: { g1: unknown }; Returns: unknown }
      st_union:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
        | {
            Args: { geom1: unknown; geom2: unknown; gridsize: number }
            Returns: unknown
          }
      st_voronoilines: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_voronoipolygons: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_wkbtosql: { Args: { wkb: string }; Returns: unknown }
      st_wkttosql: { Args: { "": string }; Returns: unknown }
      st_wrapx: {
        Args: { geom: unknown; move: number; wrap: number }
        Returns: unknown
      }
      stage_board: { Args: { p_park_id: string }; Returns: Json }
      stage_points: {
        Args: { p_stage_ids: string[] }
        Returns: {
          id: string
          lat: number
          lng: number
          name: string
        }[]
      }
      start_driver_day: {
        Args: {
          p_corridor_id: string
          p_home_label?: string
          p_layout_id: string
          p_route_id?: string
          p_shift_end?: string
          p_shift_start?: string
          p_vehicle_id: string
        }
        Returns: Json
      }
      start_trip: { Args: { p_trip_id: string }; Returns: Json }
      store_itinerary_prepared_plan: {
        Args: { p_prepared_plan: Json; p_stop_id: string }
        Returns: undefined
      }
      store_transfer_walk_prefetch: {
        Args: { p_directions: Json; p_trip_id: string }
        Returns: undefined
      }
      submit_verification: {
        Args: {
          p_client_ocr_hint?: string
          p_document_type: string
          p_storage_path: string
          p_vehicle_id?: string
        }
        Returns: Json
      }
      suggest_known_route: { Args: never; Returns: Json }
      suggested_stop_price: {
        Args: { p_location: Json; p_profile_id: string; p_sequence: number }
        Returns: number
      }
      throws_ok: { Args: { "": string }; Returns: string }
      todo:
        | { Args: { how_many: number }; Returns: boolean[] }
        | { Args: { how_many: number; why: string }; Returns: boolean[] }
        | { Args: { why: string }; Returns: boolean[] }
        | { Args: { how_many: number; why: string }; Returns: boolean[] }
      todo_end: { Args: never; Returns: boolean[] }
      todo_start:
        | { Args: never; Returns: boolean[] }
        | { Args: { "": string }; Returns: boolean[] }
      transfer_prefetch_context: { Args: { p_trip_id: string }; Returns: Json }
      transition_standing: {
        Args: {
          p_actor_id: string
          p_actor_type: Database["public"]["Enums"]["actor_type"]
          p_driver_id: string
          p_reason: string
          p_to_standing: Database["public"]["Enums"]["driver_standing"]
        }
        Returns: {
          actor_id: string | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          balance_at: number | null
          created_at: string
          driver_id: string
          from_standing: Database["public"]["Enums"]["driver_standing"] | null
          id: number
          reason: string
          to_standing: Database["public"]["Enums"]["driver_standing"]
        }
        SetofOptions: {
          from: "*"
          to: "driver_standing_transitions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      trip_contact_target: {
        Args: { p_caller: string; p_trip_id: string }
        Returns: Json
      }
      trip_location_sample: {
        Args: { p_points: Json; p_trip_id: string }
        Returns: Json
      }
      trip_payable_total: { Args: { p_trip_id: string }; Returns: number }
      trip_snapshot: { Args: { p_trip_id: string }; Returns: Json }
      trip_transition: {
        Args: {
          p_actor_id?: string
          p_actor_type: Database["public"]["Enums"]["actor_type"]
          p_meta?: Json
          p_reason?: string
          p_to_status: Database["public"]["Enums"]["trip_status"]
          p_trip_id: string
        }
        Returns: undefined
      }
      tripview_disclosure_violations: {
        Args: { p_view: Json }
        Returns: string[]
      }
      unlockrows: { Args: { "": string }; Returns: number }
      update_itinerary_stops: {
        Args: { p_itinerary_id: string; p_ops: Json }
        Returns: Json
      }
      update_sos: { Args: { p_sos_id: string }; Returns: Json }
      updategeometrysrid: {
        Args: {
          catalogn_name: string
          column_name: string
          new_srid_in: number
          schema_name: string
          table_name: string
        }
        Returns: string
      }
      upsert_emergency_contact: {
        Args: { p_display_name: string; p_id?: string; p_phone_e164: string }
        Returns: Json
      }
      upsert_rider_payment_method: {
        Args: {
          p_authorization_code: string
          p_bank?: string
          p_brand?: string
          p_exp_month?: number
          p_exp_year?: number
          p_last4?: string
          p_set_default?: boolean
        }
        Returns: string
      }
      upsert_route_profile: { Args: { p_profile: Json }; Returns: Json }
      vehicle_card_for_trip: { Args: { p_trip_id: string }; Returns: Json }
      verification_doc_provider: {
        Args: { p_country_code: string; p_document_type: string }
        Returns: string
      }
      verification_doc_type_allowed: {
        Args: { p_country_code: string; p_document_type: string }
        Returns: boolean
      }
      verification_required_doc_types: {
        Args: { p_country_code: string }
        Returns: string[]
      }
      verification_storage_path_valid: {
        Args: { p_storage_path: string; p_user_id: string }
        Returns: boolean
      }
      verify_candidate_token: {
        Args: { p_city_id?: string; p_token: string }
        Returns: {
          driver_id: string
          session_id: string
        }[]
      }
      verify_payment_token: {
        Args: { p_city_id?: string; p_token: string }
        Returns: {
          amount: number
          driver_id: string
          trip_id: string
        }[]
      }
      verify_trip_pin: {
        Args: { p_pin: string; p_trip_id: string }
        Returns: Json
      }
      wallet_buy_pass: { Args: { p_idempotency_key: string }; Returns: Json }
      wallet_ledger_check: {
        Args: never
        Returns: {
          detail: number
          problem: string
          ref: string
        }[]
      }
      wallet_request_split: {
        Args: {
          p_idempotency_key: string
          p_phones: string[]
          p_share: number
          p_trip_id: string
        }
        Returns: Json
      }
      wallet_send: {
        Args: {
          p_amount: number
          p_idempotency_key: string
          p_to_phone: string
        }
        Returns: Json
      }
      wallet_settle_split: {
        Args: {
          p_accept: boolean
          p_idempotency_key: string
          p_split_id: string
        }
        Returns: Json
      }
      wallet_top_up: {
        Args: { p_amount: number; p_idempotency_key: string }
        Returns: Json
      }
      weighted_median_fare: {
        Args: { p_fares: number[]; p_weights: number[] }
        Returns: number
      }
      women_only_matching_enabled: {
        Args: { p_city_id: string }
        Returns: boolean
      }
    }
    Enums: {
      actor_type: "rider" | "driver" | "system" | "admin"
      admin_role:
        | "superadmin"
        | "ops_lead"
        | "ops_agent"
        | "verifier"
        | "safety"
        | "finance"
        | "analyst"
        | "city_admin"
        | "operator_viewer"
        | "corporate_admin"
      city_status: "pre_seed" | "alpha" | "beta" | "live" | "paused"
      config_scope: "global" | "country" | "city" | "corridor"
      corporate_account_status: "active" | "suspended"
      corporate_invoice_status: "draft" | "generated" | "sent" | "paid"
      correction_status: "pending" | "approved" | "rejected" | "auto_merged"
      doc_status: "pending" | "approved" | "rejected" | "expired"
      driver_payout_status: "pending" | "confirmed" | "failed"
      driver_standing:
        | "good_standing"
        | "warned"
        | "matching_paused"
        | "deactivated"
        | "guarantor_referred"
      eta_band: "none" | "single" | "full"
      flag_status: "open" | "cleared" | "actioned"
      flag_type:
        | "premature_conversion"
        | "undeclared_extension"
        | "route_deviation"
        | "profile_price_mismatch"
        | "rider_no_show_pattern"
      graph_verification: "candidate" | "crowd_verified" | "field_verified"
      guarantor_type: "fellow_driver" | "vehicle_owner"
      incident_status: "open" | "triaged" | "resolved" | "dismissed"
      incident_type:
        | "safety"
        | "fare_dispute"
        | "vehicle_quality"
        | "driver_behavior"
        | "rider_behavior"
        | "lost_item"
        | "other"
      itinerary_status: "active" | "completed" | "abandoned"
      journey_status:
        | "planning"
        | "active"
        | "transfer"
        | "completed"
        | "abandoned"
      ledger_actor: "system" | "admin" | "agent" | "payment_webhook"
      ledger_adjustment_status: "pending" | "approved" | "rejected"
      ledger_entry_type:
        | "cash_commission_debit"
        | "digital_settlement_credit"
        | "onboarding_deposit"
        | "deposit_drawdown"
        | "payout_debit"
        | "manual_adjustment"
      load_size: "small" | "medium" | "large"
      negotiation_context: "park" | "roaming" | "extension" | "load_surcharge"
      negotiation_status: "open" | "agreed" | "lapsed" | "declined"
      operator_account_type: "park" | "union" | "vehicle_owner" | "corporate"
      operator_billing_status: "active" | "suspended"
      payment_method: "cash" | "digital"
      placement_context_type: "destination" | "park" | "corridor"
      presence_status:
        | "offline"
        | "at_park"
        | "roaming_available"
        | "roaming_full"
      settlement_channel:
        | "paystack_transfer"
        | "paystack_ussd"
        | "paystack_card"
        | "agent_cash"
        | "bank_manual"
      settlement_status: "pending" | "confirmed" | "failed" | "expired"
      sos_status: "open" | "acknowledged" | "resolved" | "false_alarm"
      source_type:
        | "field_agent"
        | "driver_declared"
        | "rider_correction"
        | "driver_correction"
        | "presence_cluster"
        | "trace_inference"
        | "pricing_negotiation"
        | "admin"
        | "import"
      stop_status: "pending" | "in_progress" | "completed" | "skipped"
      trace_quality: "none" | "partial" | "good"
      trip_status:
        | "requested"
        | "accepted"
        | "boarded"
        | "in_transit"
        | "completed"
        | "declined"
        | "expired"
        | "cancelled_by_rider"
        | "cancelled_by_driver"
        | "no_show"
        | "released_before_arrival"
      verified_status:
        | "unverified"
        | "pending"
        | "verified"
        | "rejected"
        | "suspended"
    }
    CompositeTypes: {
      _time_trial_type: {
        a_time: number | null
      }
      fare_resolution: {
        quote_id: string | null
        amount: number | null
        currency: string | null
        tier: number | null
        confidence: number | null
        components: Json | null
        unconfirmed: boolean | null
        load_surcharge_pending: boolean | null
      }
      geometry_dump: {
        path: number[] | null
        geom: unknown
      }
      valid_detail: {
        valid: boolean | null
        reason: string | null
        location: unknown
      }
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      actor_type: ["rider", "driver", "system", "admin"],
      admin_role: [
        "superadmin",
        "ops_lead",
        "ops_agent",
        "verifier",
        "safety",
        "finance",
        "analyst",
        "city_admin",
        "operator_viewer",
        "corporate_admin",
      ],
      city_status: ["pre_seed", "alpha", "beta", "live", "paused"],
      config_scope: ["global", "country", "city", "corridor"],
      corporate_account_status: ["active", "suspended"],
      corporate_invoice_status: ["draft", "generated", "sent", "paid"],
      correction_status: ["pending", "approved", "rejected", "auto_merged"],
      doc_status: ["pending", "approved", "rejected", "expired"],
      driver_payout_status: ["pending", "confirmed", "failed"],
      driver_standing: [
        "good_standing",
        "warned",
        "matching_paused",
        "deactivated",
        "guarantor_referred",
      ],
      eta_band: ["none", "single", "full"],
      flag_status: ["open", "cleared", "actioned"],
      flag_type: [
        "premature_conversion",
        "undeclared_extension",
        "route_deviation",
        "profile_price_mismatch",
        "rider_no_show_pattern",
      ],
      graph_verification: ["candidate", "crowd_verified", "field_verified"],
      guarantor_type: ["fellow_driver", "vehicle_owner"],
      incident_status: ["open", "triaged", "resolved", "dismissed"],
      incident_type: [
        "safety",
        "fare_dispute",
        "vehicle_quality",
        "driver_behavior",
        "rider_behavior",
        "lost_item",
        "other",
      ],
      itinerary_status: ["active", "completed", "abandoned"],
      journey_status: [
        "planning",
        "active",
        "transfer",
        "completed",
        "abandoned",
      ],
      ledger_actor: ["system", "admin", "agent", "payment_webhook"],
      ledger_adjustment_status: ["pending", "approved", "rejected"],
      ledger_entry_type: [
        "cash_commission_debit",
        "digital_settlement_credit",
        "onboarding_deposit",
        "deposit_drawdown",
        "payout_debit",
        "manual_adjustment",
      ],
      load_size: ["small", "medium", "large"],
      negotiation_context: ["park", "roaming", "extension", "load_surcharge"],
      negotiation_status: ["open", "agreed", "lapsed", "declined"],
      operator_account_type: ["park", "union", "vehicle_owner", "corporate"],
      operator_billing_status: ["active", "suspended"],
      payment_method: ["cash", "digital"],
      placement_context_type: ["destination", "park", "corridor"],
      presence_status: [
        "offline",
        "at_park",
        "roaming_available",
        "roaming_full",
      ],
      settlement_channel: [
        "paystack_transfer",
        "paystack_ussd",
        "paystack_card",
        "agent_cash",
        "bank_manual",
      ],
      settlement_status: ["pending", "confirmed", "failed", "expired"],
      sos_status: ["open", "acknowledged", "resolved", "false_alarm"],
      source_type: [
        "field_agent",
        "driver_declared",
        "rider_correction",
        "driver_correction",
        "presence_cluster",
        "trace_inference",
        "pricing_negotiation",
        "admin",
        "import",
      ],
      stop_status: ["pending", "in_progress", "completed", "skipped"],
      trace_quality: ["none", "partial", "good"],
      trip_status: [
        "requested",
        "accepted",
        "boarded",
        "in_transit",
        "completed",
        "declined",
        "expired",
        "cancelled_by_rider",
        "cancelled_by_driver",
        "no_show",
        "released_before_arrival",
      ],
      verified_status: [
        "unverified",
        "pending",
        "verified",
        "rejected",
        "suspended",
      ],
    },
  },
} as const

