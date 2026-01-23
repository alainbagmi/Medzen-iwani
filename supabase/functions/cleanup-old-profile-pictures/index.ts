// Cleanup Old Profile Pictures Edge Function
// Deletes old profile pictures, keeping only the newest one per user
// Works for ALL roles: Patient, Medical Provider, Facility Admin, System Admin
// Path structure: pics/{firebase_uid}/timestamp.jpeg
// Can be called manually or scheduled via cron

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  const origin = req.headers.get('origin');
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    // Create Supabase client with service role (can bypass RLS)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    );

    // Get optional firebase_uid parameter to clean specific user
    const { firebase_uid } = await req.json().catch(() => ({}));

    // Step 1: Get all user folders or a specific user folder
    const picsFolder = 'pics';
    let userFolders: string[] = [];

    if (firebase_uid) {
      // Clean specific user only
      userFolders = [firebase_uid];
    } else {
      // Get all user folders (all roles)
      const { data: folders, error: foldersError } = await supabaseAdmin
        .storage
        .from('profile_pictures')
        .list(picsFolder, {
          limit: 10000, // Support large number of users
        });

      if (foldersError) {
        throw foldersError;
      }

      // Filter out actual folders (they have null id and created_at)
      // This gets all user folders regardless of role
      userFolders = folders
        ?.filter(f => !f.id && f.name && f.name !== '.emptyFolderPlaceholder')
        .map(f => f.name) || [];
    }

    if (userFolders.length === 0) {
      return new Response(
        JSON.stringify({
          message: 'No user folders found',
          deleted: 0,
          users_processed: 0
        }),
        { headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`Processing ${userFolders.length} user folder(s)`);

    // Step 2: For each user, keep only the newest file
    const deletedFiles: string[] = [];
    let usersProcessed = 0;

    for (const userId of userFolders) {
      const userPath = `${picsFolder}/${userId}`;

      // Get all files for this user
      const { data: files, error: listError } = await supabaseAdmin
        .storage
        .from('profile_pictures')
        .list(userPath, {
          limit: 100,
          sortBy: { column: 'created_at', order: 'desc' }
        });

      if (listError) {
        console.error(`Error listing files for user ${userId}:`, listError);
        continue;
      }

      if (!files || files.length === 0) {
        console.log(`No files found for user ${userId}`);
        continue;
      }

      // Filter out folder placeholders
      const actualFiles = files.filter(f => f.name && f.name !== '.emptyFolderPlaceholder' && f.id);

      if (actualFiles.length <= 1) {
        console.log(`User ${userId} has ${actualFiles.length} file(s) - no cleanup needed`);
        usersProcessed++;
        continue;
      }

      // Sort by created_at descending (newest first) - defensive sort in case list sort didn't work
      actualFiles.sort((a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
      );

      // Keep the first (newest) file, delete the rest
      const filesToDelete = actualFiles.slice(1);

      for (const file of filesToDelete) {
        const fullPath = `${userPath}/${file.name}`;

        const { error: deleteError } = await supabaseAdmin
          .storage
          .from('profile_pictures')
          .remove([fullPath]);

        if (deleteError) {
          console.error(`Failed to delete ${fullPath}:`, deleteError);
        } else {
          deletedFiles.push(fullPath);
          console.log(`Deleted old profile picture: ${fullPath}`);
        }
      }

      usersProcessed++;
    }

    return new Response(
      JSON.stringify({
        message: 'Cleanup completed',
        deleted: deletedFiles.length,
        files: deletedFiles,
        users_processed: usersProcessed,
        total_user_folders: userFolders.length
      }),
      { headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Cleanup error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});
