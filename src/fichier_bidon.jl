"""
    return_true()

Always return the boolean `true`.

# See also

- nothing
"""
function return_true()
    return true
end

function return_false()
    return !return_true()
end
