const GoogleStrategy = require('passport-google-oauth20').Strategy;
const mongoose = require('mongoose');
const User = require('../models/User');

module.exports = function(passport) {
  passport.use(
    new GoogleStrategy(
      {
        clientID: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        // Ensure this matches the authorized redirect URI in Google Cloud Console
        callbackURL: 'https://storybooks-staging.faizolam.com/auth/google/callback',
      },
      async (accessToken, refreshToken, profile, done) => {
        const newUser = {
          googleId: profile.id,
          displayName: profile.displayName,
          firstName: profile.name.givenName,
          lastName: profile.name.familyName,
          image: profile.photos[0].value,
        };

        try {
          // Check if user already exists.
          let user = await User.findOne({ googleId: profile.id });

          if (user) {
            // User already exists, return the user
            done(null, user);
          } else {
            // Create a new user in the database
            user = await User.create(newUser);
            done(null, user);
          }
        } catch (err) {
          console.error(err);
          done(err, null); // Pass error to done
        }
      }
    )
  );

  // Serialize user to store in session
  passport.serializeUser((user, done) => {
    done(null, user.id); // Store user ID in session
  });

  // Deserialize user from session
  passport.deserializeUser((id, done) => {
    User.findById(id, (err, user) => {
      done(err, user); // Retrieve user from database using ID
    });
  });
};