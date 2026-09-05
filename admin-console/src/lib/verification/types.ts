export type VerificationQueueRow = {
  id: string;
  driver_id: string;
  document_type: string;
  status: 'pending' | 'approved' | 'rejected' | 'expired';
  submitted_at: string;
  storage_path: string | null;
  ocr_extract: Record<string, unknown> | null;
  face_match_score: number | null;
  vehicle_id: string | null;
  driver_display_name: string | null;
  driver_gender: string | null;
  driver_phone_masked: string | null;
  vehicle_plate: string | null;
  vehicle_color: string | null;
  vehicle_make_model: string | null;
  vehicle_seat_capacity: number | null;
  duplicate: boolean;
  other_driver_masked: string | null;
};

export type DuplicateCheck = {
  duplicate: boolean;
  other_driver_masked?: string | null;
};
