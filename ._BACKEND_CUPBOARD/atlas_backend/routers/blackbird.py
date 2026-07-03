"""Legacy compatibility shim for the former Blackbird router module."""

try:
    from .chukya_sensor_fusion import router
except ImportError:
    from chukya_sensor_fusion import router


__all__ = ['router']
