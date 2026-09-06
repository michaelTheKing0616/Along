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
          created_at: string
          deployment_id: string | null
          disabled_at: string | null
          id: string
          role: Database["public"]["Enums"]["admin_role"]
          updated_at: string
        }
        Insert: {
          city_scope?: string[] | null
          created_at?: string
          deployment_id?: string | null
          disabled_at?: string | null
          id: string
          role: Database["public"]["Enums"]["admin_role"]
          updated_at?: string
        }
        Update: {
          city_scope?: string[] | null
          created_at?: string
          deployment_id?: string | null
          disabled_at?: string | null
          id?: string
          role?: Database["public"]["Enums"]["admin_role"]
          updated_at?: string
        }
        Relationships: [
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
          load_capacity: string
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
          load_capacity: string
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
          load_capacity?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
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
      profiles: {
        Row: {
          avatar_path: string | null
          created_at: string
          display_name: string | null
          gender: string | null
          id: string
          locale: string
          phone_e164: string | null
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
          updated_at?: string
        }
        Relationships: []
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
    }
    Views: {
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
      _cleanup: { Args: never; Returns: boolean }
      _contract_on: { Args: { "": string }; Returns: unknown }
      _currtest: { Args: never; Returns: number }
      _db_privs: { Args: never; Returns: unknown[] }
      _extensions: { Args: never; Returns: unknown[] }
      _field_payload_point: { Args: { p_payload: Json }; Returns: unknown }
      _get: { Args: { "": string }; Returns: number }
      _get_latest: { Args: { "": string }; Returns: number[] }
      _get_note: { Args: { "": string }; Returns: string }
      _is_verbose: { Args: never; Returns: boolean }
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
      _planner_stages_at_park: {
        Args: { p_city_id: string; p_park_id: string }
        Returns: {
          mode_code: string
          route_id: string
          stage_id: string
        }[]
      }
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
      admin_can_access_city: { Args: { p_city: string }; Returns: boolean }
      admin_approve_verification: {
        Args: { p_verification_id: string; p_women_only_eligible?: boolean }
        Returns: Json
      }
      admin_reject_verification: {
        Args: { p_verification_id: string; p_reason: string }
        Returns: Json
      }
      admin_log_view_document: {
        Args: { p_verification_id: string }
        Returns: Json
      }
      admin_check_identity_duplicate: {
        Args: { p_verification_id: string }
        Returns: Json
      }
      admin_review_fare_correction: {
        Args: { id: string; action: string; note?: string }
        Returns: Json
      }
      admin_publish_field_entity: {
        Args: { p_reconciliation_id: string }
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
      cfg: {
        Args: { p_city?: string; p_corridor?: string; p_key: string }
        Returns: Json
      }
      cfg_num: {
        Args: { p_city?: string; p_corridor?: string; p_key: string }
        Returns: number
      }
      city_for_point: { Args: { p: unknown }; Returns: string }
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
      compute_field_variance: {
        Args: { p_submission_a: string; p_submission_b: string }
        Returns: Json
      }
      compute_trust_weights: { Args: never; Returns: undefined }
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
      confirmer_trust_weight: {
        Args: { p_city_id?: string; p_profile_id: string; p_role: string }
        Returns: number
      }
      current_profile_id: { Args: never; Returns: string }
      decay_confidence: { Args: never; Returns: undefined }
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
      distance_m: { Args: { a: unknown; b: unknown }; Returns: number }
      do_tap:
        | { Args: never; Returns: string[] }
        | { Args: { "": string }; Returns: string[] }
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
      equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      fail:
        | { Args: never; Returns: string }
        | { Args: { "": string }; Returns: string }
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
      findfuncs: { Args: { "": string }; Returns: string[] }
      fingerprint_collusion_factor: {
        Args: { p_city_id?: string; p_profile_id: string }
        Returns: number
      }
      finish: { Args: { exception_on_failure?: boolean }; Returns: string[] }
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
      gettransactionid: { Args: never; Returns: unknown }
      graph_target_city_id: {
        Args: { p_target_id: string; p_target_type: string }
        Returns: string
      }
      has_admin_role: { Args: { roles: string[] }; Returns: boolean }
      has_unique: { Args: { "": string }; Returns: string }
      in_todo: { Args: never; Returns: boolean }
      infer_confirmer_role: { Args: { p_profile_id: string }; Returns: string }
      is_admin: { Args: never; Returns: boolean }
      is_empty: { Args: { "": string }; Returns: string }
      isnt_empty: { Args: { "": string }; Returns: string }
      lives_ok: { Args: { "": string }; Returns: string }
      longtransactionsenabled: { Args: never; Returns: boolean }
      no_plan: { Args: never; Returns: boolean[] }
      num_failed: { Args: never; Returns: number }
      os_name: { Args: never; Returns: string }
      pass:
        | { Args: never; Returns: string }
        | { Args: { "": string }; Returns: string }
      pg_version: { Args: never; Returns: string }
      pg_version_num: { Args: never; Returns: number }
      pgtap_version: { Args: never; Returns: number }
      planner_decompose: {
        Args: {
          p_city_id?: string
          p_destination_park_id: string
          p_origin_park_id: string
        }
        Returns: Json
      }
      populate_geometry_columns:
        | { Args: { tbl_oid: unknown; use_typmod?: boolean }; Returns: number }
        | { Args: { use_typmod?: boolean }; Returns: string }
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
      promote_candidates: { Args: never; Returns: undefined }
      reconcile_field_submission: {
        Args: { p_submission_id: string }
        Returns: string
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
      rider_trust_weight: {
        Args: { p_city_id?: string; p_rider_id: string }
        Returns: number
      }
      runtests:
        | { Args: never; Returns: string[] }
        | { Args: { "": string }; Returns: string[] }
      show_limit: { Args: never; Returns: number }
      show_trgm: { Args: { "": string }; Returns: string[] }
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
      unlockrows: { Args: { "": string }; Returns: number }
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
      weighted_median_fare: {
        Args: { p_fares: number[]; p_weights: number[] }
        Returns: number
      }
    }
    Enums: {
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
      correction_status: "pending" | "approved" | "rejected" | "auto_merged"
      doc_status: "pending" | "approved" | "rejected" | "expired"
      driver_standing:
        | "good_standing"
        | "warned"
        | "matching_paused"
        | "deactivated"
        | "guarantor_referred"
      graph_verification: "candidate" | "crowd_verified" | "field_verified"
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
      correction_status: ["pending", "approved", "rejected", "auto_merged"],
      doc_status: ["pending", "approved", "rejected", "expired"],
      driver_standing: [
        "good_standing",
        "warned",
        "matching_paused",
        "deactivated",
        "guarantor_referred",
      ],
      graph_verification: ["candidate", "crowd_verified", "field_verified"],
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

