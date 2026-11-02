# Private Academy demo validation

Date: 2026-11-02

The owner supplied a short MP4 for private technical testing. No video bytes, access codes, signed URLs or customer details are stored in this repository.

Verified against the deployed API and real private Storage object:

- Upload completed into the private video bucket.
- Uploaded file is H.264 MP4, 576 × 1024, 23.266667 seconds; no audio stream.
- Private test tutorial is excluded from public catalog using the is_test flag.
- Server-generated code authorized its assigned tutorial.
- Downloaded authorized video matched the uploaded file byte for byte.
- Reusing the code with the same browser token succeeded.
- A different browser token was rejected with HTTP 403.
- A different tutorial ID was rejected with HTTP 403.
- Revoking the code rejected new playback authorization with HTTP 403.
- Browser preview decoded the video and played through to ended=true with no media error.

Final state: video remains private; demo tutorial is an unpublished test draft; test access code is revoked. Existing signed URLs have their normal five-minute expiry. The demo is not offered for sale.

This validates backend authorization and media playback. It does not replace testing the owner's signed-in admin workflow on her laptop or Safari. Subtitles cannot be transcribed from this silent file; a recording with spoken audio is required.
