# Lottie Animation Sources for SpareWo

Since the previous links were dead, here are alternative sources for high-quality Lottie animations:

## 1. LottieFiles (Free animations)

### Car/Automotive Animations:
- **Car Service**: https://lottiefiles.com/animations/car-service-UJzRGVPLxm
- **Car Repair**: https://lottiefiles.com/animations/car-repair-animation-Xk1vvXkL6O
- **Car Loading**: https://lottiefiles.com/animations/car-fKJQE45a7e

### General Purpose:
- **Welcome**: https://lottiefiles.com/animations/welcome-screen-loader-3rJIcb3P5l
- **Success**: https://lottiefiles.com/animations/success-lVVQGGQWdU
- **Loading**: https://lottiefiles.com/animations/loading-B1SssXCBKN

### Cart/Shopping:
- **Add to Cart**: https://lottiefiles.com/animations/add-to-cart-Re6TkPlsL7
- **Empty Cart**: https://lottiefiles.com/animations/empty-cart-kfPMkcnJIl

## 2. Alternative: Use Icon Animations

If you can't find suitable Lottie files, you can use Flutter's built-in animation capabilities:

```dart
// Example: Animated car icon
AnimatedContainer(
  duration: const Duration(seconds: 1),
  curve: Curves.easeInOut,
  width: _isAnimated ? 120 : 100,
  height: _isAnimated ? 120 : 100,
  child: Icon(
    Icons.directions_car,
    size: _isAnimated ? 60 : 50,
    color: AppColors.primary,
  ),
)
```

## 3. Create Simple Animations with Rive

Rive (https://rive.app) offers:
- Free tier with basic animations
- Easy-to-use editor
- Flutter package: `rive`

## 4. Free Resources:
- **IconScout**: https://iconscout.com/lottie-animations
- **Drawer**: https://drawer.design/products/lottie-animations
- **LordIcon**: https://lordicon.com (animated icons)

## 5. How to Download and Use:

1. Visit the link
2. Click "Download" and select "Lottie JSON"
3. Save to `assets/animations/`
4. Use in your app:

```dart
Lottie.asset(
  'assets/animations/your_animation.json',
  width: 200,
  height: 200,
  fit: BoxFit.contain,
)
```

## 6. Fallback Strategy

The app already includes fallback icons when Lottie files are missing, so it will work even without animations!
