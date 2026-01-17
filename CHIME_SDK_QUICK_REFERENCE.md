# Chime SDK Quick Reference

## ✅ What Was Fixed

**Problem:** Video calls broken - SDK wouldn't load  
**Cause:** AWS CloudFront CDN serving broken bundle  
**Solution:** Built custom browser bundle from npm  

## 📦 Bundle Details

- **File:** `web/assets/amazon-chime-sdk-medzen.min.js`
- **Size:** 1.1 MB
- **Version:** 3.29.0
- **Classes:** 223

## 🔧 How to Rebuild (if needed)

```bash
# Install dependencies (already done)
npm install

# Rebuild bundle
npx webpack --config webpack.config.js

# Output: web/assets/amazon-chime-sdk-medzen.min.js
```

## 📱 Testing Video Calls

1. Build Flutter app: `flutter build web`
2. Start local server or deploy
3. Create video call meeting
4. Check browser console for: "✅ MedZen Chime SDK Bundle loaded successfully"

## 🚨 Troubleshooting

**SDK not loading?**
- Check browser console for errors
- Verify `web/assets/amazon-chime-sdk-medzen.min.js` exists
- Ensure widgets use `./assets/amazon-chime-sdk-medzen.min.js` path

**Build fails?**
- Run `npm install` first
- Check Node.js version (requires v14+)

**Video calls still broken?**
- Check Chime meeting token validity
- Verify Firebase/Supabase Edge Function is working
- Test with browser console open for detailed logs
