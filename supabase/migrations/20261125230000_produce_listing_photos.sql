alter table public.produce_listings
  add column photo_base64 text,
  add column photo_description text,
  add constraint produce_listing_photo_pair check (
    (photo_base64 is null and photo_description is null)
    or (
      photo_base64 is not null
      and char_length(photo_base64) between 16 and 1398104
      and photo_base64 ~ '^(/9j/|iVBORw0KGgo|UklGR|R0lGOD)[A-Za-z0-9+/]+={0,2}$'
      and photo_description is not null
      and char_length(btrim(photo_description)) between 1 and 160
    )
  );
