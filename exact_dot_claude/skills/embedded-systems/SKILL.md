---
name: embedded-systems
description: |
  Embedded systems programming with ESP32/ESP-IDF, STM32, FreeRTOS, real-time systems,
  and hardware abstraction. Covers low-level development, RTOS patterns, peripheral
  drivers, and firmware workflows.
  Use when user mentions ESP32, ESP-IDF, STM32, FreeRTOS, embedded, microcontroller,
  firmware, RTOS, or hardware programming.
allowed-tools: Glob, Grep, Read, Edit, Write, Bash
---

# Embedded Systems

Expert knowledge for low-level embedded development with focus on ESP32/ESP-IDF, STM32, real-time systems, and hardware interfaces.

## Core Expertise

**ESP32 & ESP-IDF Mastery**
- Master ESP-IDF framework with command-line tools: `idf.py build`, `idf.py flash`, `idf.py monitor`
- Implement FreeRTOS task management, queues, semaphores, and inter-task communication
- Configure ESP32 peripherals: GPIO, ADC, DAC, PWM, SPI, I2C, UART, WiFi, Bluetooth
- Design power management strategies including deep sleep, light sleep, and power optimization

## Key Capabilities

**STM32 Development**
- STM32CubeMX configuration and HAL library integration
- Real-time system design with interrupt handling and priority management
- Hardware abstraction layer (HAL) implementation and optimization
- Debug workflows with ST-Link, GDB, and hardware debugging tools

**Real-Time Systems Programming**
- **FreeRTOS**: Task scheduling, priority management, and resource sharing
- **Interrupt Handling**: ISR design, interrupt priorities, and latency optimization
- **Memory Management**: Stack allocation, heap management, and memory optimization
- **Timing Constraints**: Meeting real-time deadlines and system responsiveness

**Hardware Interface Programming**
- **Communication Protocols**: SPI, I2C, UART, CAN bus implementation
- **Sensor Integration**: ADC conversion, sensor calibration, and data filtering
- **Actuator Control**: PWM generation, motor control, and servo management
- **Wireless Communication**: WiFi, Bluetooth, LoRa, and wireless protocol implementation

**Performance Optimization**
- **Memory Optimization**: Flash usage, RAM optimization, and code size reduction
- **Power Optimization**: Sleep modes, peripheral management, and battery life extension
- **Processing Optimization**: CPU usage optimization and real-time performance tuning
- **Communication Optimization**: Protocol efficiency and data transmission optimization

## Essential Commands

```bash
# ESP-IDF workflow
idf.py set-target esp32
idf.py menuconfig
idf.py build
idf.py -p /dev/ttyUSB0 flash
idf.py -p /dev/ttyUSB0 monitor

# STM32 workflow (with STM32CubeIDE CLI)
cmake -B build -DCMAKE_TOOLCHAIN_FILE=arm-none-eabi.cmake
cmake --build build
st-flash write build/firmware.bin 0x8000000

# Debugging
arm-none-eabi-gdb build/firmware.elf
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg
```

## Best Practices

**Real-Time System Design**
- Design deterministic systems with predictable timing behavior
- Implement proper interrupt priorities and resource sharing mechanisms
- Use appropriate synchronization primitives for inter-task communication
- Optimize critical code sections for timing requirements

**Hardware Integration**
- Follow proper electrical engineering practices for signal integrity
- Implement robust error handling for hardware failures and edge cases
- Design for electromagnetic compatibility (EMC) and interference resistance
- Use appropriate pull-up/pull-down resistors and signal conditioning

**Code Organization**
- Structure code with clear hardware abstraction layers
- Implement modular design for reusable peripheral drivers
- Use proper naming conventions for embedded systems programming
- Maintain clear separation between application logic and hardware drivers

**FreeRTOS Task Example**
```c
void task_handler(void *parameters) {
    TickType_t last_wake_time = xTaskGetTickCount();
    const TickType_t frequency = pdMS_TO_TICKS(100);  // 100ms period

    for (;;) {
        // Task work here
        read_sensors();
        process_data();
        update_outputs();

        // Wait for next cycle
        vTaskDelayUntil(&last_wake_time, frequency);
    }
}
```

**Interrupt Handling**
```c
void IRAM_ATTR gpio_isr_handler(void* arg) {
    uint32_t gpio_num = (uint32_t) arg;
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;

    // Minimal ISR work
    xQueueSendFromISR(gpio_evt_queue, &gpio_num, &xHigherPriorityTaskWoken);

    if (xHigherPriorityTaskWoken) {
        portYIELD_FROM_ISR();
    }
}
```

For detailed peripheral configuration, power management strategies, communication protocol implementations, and debugging techniques, see REFERENCE.md.
