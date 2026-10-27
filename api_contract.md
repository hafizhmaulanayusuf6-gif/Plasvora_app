# PLASVORA — Draft API Contract

This is a coordination document for the Flutter and Laravel developers. Agree on endpoint names and JSON before integrating. These paths are proposed, not proof that a backend has already been implemented.

## Conventions

- Base path: `/api`
- Request/response content type: `application/json` except file uploads.
- Use consistent JSON keys (snake_case recommended for API payloads).
- Return appropriate HTTP statuses (200/201 success, 400/422 validation, 401 unauthenticated, 403 unauthorized, 404 not found, 500 unexpected error).
- Never expose exact home address publicly in a listing.

## Suggested endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/materials` | Browse available material listings; optionally support `q`, `category`, `condition`, `min_weight`, `max_weight`, `location` filters |
| POST | `/api/materials` | Create a material listing |
| GET | `/api/materials/{id}` | Get listing details |
| PATCH | `/api/materials/{id}` | Update listing owned by current user |
| DELETE | `/api/materials/{id}` | Remove/deactivate a listing owned by current user |
| GET | `/api/material-requests` | Browse requests for material |
| POST | `/api/material-requests` | Create a request/need |
| GET | `/api/material-requests/{id}` | Get a material need detail |
| POST | `/api/handover-requests` | Request a material listing |
| PATCH | `/api/handover-requests/{id}/status` | Update status with authorization rules |
| GET | `/api/activities` | Get current user's activity/transaction history |
| POST | `/api/analyses` | Optional: save a plastic analysis record |

## Example: GET `/api/materials`

```json
{
  "success": true,
  "message": "Materials retrieved successfully",
  "data": [
    {
      "id": 101,
      "owner_id": 12,
      "name": "Tutup Botol Plastik",
      "category": "PP",
      "weight_kg": 5.0,
      "condition": "clean",
      "price": 15000,
      "is_free": false,
      "general_location": "Cianjur",
      "description": "Tutup botol sudah dipilah.",
      "image_url": null,
      "status": "available",
      "created_at": "2026-10-27T09:00:00Z"
    }
  ]
}
```

## Example: POST `/api/materials`

```json
{
  "name": "Tutup Botol Plastik",
  "category": "PP",
  "weight_kg": 5.0,
  "condition": "clean",
  "price": 15000,
  "is_free": false,
  "general_location": "Cianjur",
  "description": "Tutup botol sudah dipilah."
}
```

Response should include the created listing and its ID. Image upload can be agreed separately; use `multipart/form-data` only if both sides are ready to implement it. Until then, `image_url` may be null or a local/demo asset may be used only in the mock repository.

## Example: POST `/api/material-requests`

```json
{
  "material_category": "PP",
  "requested_weight_kg": 10.0,
  "minimum_condition": "clean",
  "general_location": "Cianjur",
  "intended_use": "Proyek mozaik sekolah"
}
```

## Example: POST `/api/handover-requests`

```json
{
  "listing_id": 101,
  "requested_weight_kg": 5.0,
  "note": "Material diperlukan untuk proyek komunitas."
}
```

## Example status update

```json
{
  "status": "handed_over",
  "actual_weight_kg": 5.0,
  "note": "Penyerahan dikonfirmasi oleh kedua pihak."
}
```

Valid status transitions should be enforced by Laravel, not trusted solely from the client. Suggested states: `pending`, `approved`, `handed_over`, `utilization_confirmed`, `rejected`, `cancelled`.

## Error format

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "weight_kg": ["The weight field is required."]
  }
}
```

## Team agreement checklist

- [ ] Endpoint names are agreed by both developers.
- [ ] Field names, types, enum values, and validation rules are agreed.
- [ ] Auth mechanism is agreed (if required for MVP).
- [ ] API base URL per environment is documented.
- [ ] Upload flow/image URL rules are agreed.
- [ ] Ownership/authorization rules for status transitions are agreed.
