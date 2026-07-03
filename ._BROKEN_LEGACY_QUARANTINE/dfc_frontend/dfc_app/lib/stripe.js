const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

exports.createConnectAccount = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
    
    // Create a connected account for the promoter/gym
    const account = await stripe.accounts.create({
        type: "express",
        email: data.email,
    });

    await admin.firestore().collection("promoters").doc(context.auth.uid).set({
        stripeAccountId: account.id
    }, { merge: true });

    const accountLink = await stripe.accountLinks.create({
        account: account.id,
        refresh_url: "https://dfc.com/reauth",
        return_url: "https://dfc.com/dashboard",
        type: "account_onboarding",
    });

    return { url: accountLink.url };
});