return {
    error = "TRT_E", -- Something went wrong that were not in control of
    alreadyInPlace = "TRT_AIP", -- Already in the place you are trying to teleport to
    full = "TRT_F", -- The place you are trying to teleport to is full
    invalid = "TRT_I", -- The request was invalid. This error code is flexible and can be used for many different reasons
    success = "TRT_SUCCESS", -- The request was successful :D
    disabled = "TRT_D", -- The requested party is not online right now. Important for clients to detect this so they can show a message to the user
}